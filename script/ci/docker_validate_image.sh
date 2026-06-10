#!/usr/bin/env bash

set -euo pipefail
set -x

usage() {
  cat <<'USAGE'
Usage: script/ci/docker_validate_image.sh --image <image-ref> --target <slim|slim-bim|all-in-one> [--platform <docker-platform>]

Validates target-specific runtime behavior of a built docker image.
USAGE
}

log() {
  printf '[docker-validate] %s\n' "$*"
}

die() {
  printf '[docker-validate] ERROR: %s\n' "$*" >&2
  exit 1
}

IMAGE=""
TARGET=""
PLATFORM=""
VALIDATION_PORT="${VALIDATION_PORT:-18080}"
VALIDATION_TIMEOUT_SECONDS="${VALIDATION_TIMEOUT_SECONDS:-300}"
VALIDATION_CONTAINER_NAME=""

cleanup() {
  if [[ -n "${VALIDATION_CONTAINER_NAME}" ]]; then
    docker rm -f "${VALIDATION_CONTAINER_NAME}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)
      IMAGE="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    --platform)
      PLATFORM="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "${IMAGE}" ]] || { usage; die "--image is required"; }
[[ -n "${TARGET}" ]] || { usage; die "--target is required"; }

command -v docker >/dev/null 2>&1 || die "docker is required"
command -v curl >/dev/null 2>&1 || die "curl is required"

run_in_image_shell() {
  local shell_script="$1"
  docker run --rm --entrypoint sh "${IMAGE}" -lc "${shell_script}"
}

validate_plugin_and_runtime_basics() {
  run_in_image_shell "$(cat <<'SH'
set -eu

check_present() {
  if ! command -v -- "$1" >/dev/null 2>&1; then
    echo "Expected command '$1' to be present"
    exit 1
  fi
}

check_file() {
  [ -f "$1" ] || {
    echo "Expected file '$1' to exist"
    exit 1
  }
}

check_present bin/rails
bin/rails --version >/dev/null

[ "${BUNDLE_APP_CONFIG:-}" = "/app/.bundle" ] || {
  echo "Expected BUNDLE_APP_CONFIG=/app/.bundle, got '${BUNDLE_APP_CONFIG:-}'"
  exit 1
}

check_file /app/.bundle/config
grep -q 'BUNDLE_PATH: "vendor/bundle"' /app/.bundle/config || {
  echo "Missing BUNDLE_PATH in /app/.bundle/config"
  exit 1
}
grep -q 'BUNDLE_DEPLOYMENT: "true"' /app/.bundle/config || {
  echo "Missing BUNDLE_DEPLOYMENT in /app/.bundle/config"
  exit 1
}

check_file /app/config/frontend_assets.manifest.json
ls /app/public/assets/frontend/*.js >/dev/null 2>&1 || {
  echo "Expected compiled frontend javascript assets to exist"
  exit 1
}

for plugin in budgets costs openproject-avatars openproject-documents \
  openproject-github_integration openproject-gitlab_integration openproject-meeting; do
  grep -q -- "$plugin" /app/public/assets/frontend/*.js || {
    echo "Expected plugin '${plugin}' to be present in compiled frontend assets"
    exit 1
  }
done

for plugin_dir in budgets costs avatars documents github_integration gitlab_integration meeting; do
  [ -d "/app/modules/${plugin_dir}/frontend/module" ] || {
    echo "Expected plugin frontend module directory '/app/modules/${plugin_dir}/frontend/module'"
    exit 1
  }
done

check_present convert
check_present tesseract
SH
)"
}

validate_slim_pruning() {
  run_in_image_shell "$(cat <<'SH'
set -eu

check_absent_dir() {
  [ ! -d "$1" ] || {
    echo "Expected directory '$1' to be removed from slim image"
    exit 1
  }
}

check_present_dir() {
  [ -d "$1" ] || {
    echo "Expected directory '$1' to exist"
    exit 1
  }
}

check_absent_dir /app/frontend
check_absent_dir /app/spec
check_absent_dir /app/screenshots
check_absent_dir /app/lookbook
check_absent_dir /app/public/assets/lookbook
check_absent_dir /app/app/assets/videos/enterprise
check_present_dir /app/public/assets/enterprise

if find /app/public/assets -type f -name '*.map' | grep -q .; then
  echo "Expected source maps to be removed from slim runtime assets"
  exit 1
fi

if find /app/modules -mindepth 2 -maxdepth 2 -type d \
  \( -name spec -o -name test -o -name tests -o -name doc -o -name docs \) | grep -q .; then
  echo "Expected module test and doc folders to be removed from slim image"
  exit 1
fi
SH
)"
}

validate_slim() {
  validate_plugin_and_runtime_basics
  validate_slim_pruning

  run_in_image_shell "$(cat <<'SH'
set -eu

check_missing() {
  if command -v -- "$1" >/dev/null 2>&1; then
    echo "Expected command '$1' to be absent"
    exit 1
  fi
}

for tool in node npm gcc g++ make git svn hg; do
  check_missing "$tool"
done
SH
)"
}

validate_slim_bim() {
  validate_plugin_and_runtime_basics
  validate_slim_pruning

  run_in_image_shell "$(cat <<'SH'
set -eu

check_present() {
  if ! command -v -- "$1" >/dev/null 2>&1; then
    echo "Expected command '$1' to be present"
    exit 1
  fi
}

check_missing() {
  if command -v -- "$1" >/dev/null 2>&1; then
    echo "Expected command '$1' to be absent"
    exit 1
  fi
}

[ "${OPENPROJECT_EDITION:-}" = "bim" ] || {
  echo "Expected OPENPROJECT_EDITION=bim, got '${OPENPROJECT_EDITION:-}'"
  exit 1
}

for tool in node npm IfcConvert COLLADA2GLTF xeokit-metadata; do
  check_present "$tool"
done

for tool in gcc g++ make git svn hg; do
  check_missing "$tool"
done
SH
)"
}

validate_all_in_one() {
  VALIDATION_CONTAINER_NAME="openproject-validate-${RANDOM}-${RANDOM}"
  local deadline=$((SECONDS + VALIDATION_TIMEOUT_SECONDS))
  local api_url="http://127.0.0.1:${VALIDATION_PORT}/api/v3"

  local docker_run_args=(
    --name "${VALIDATION_CONTAINER_NAME}"
    -d
    -p "${VALIDATION_PORT}:80"
    -e SUPERVISORD_LOG_LEVEL=debug
    -e OPENPROJECT_LOGIN__REQUIRED=false
    -e SECRET_KEY_BASE=eijai2ii3aithieJ4teez7Gavae4chai
    -e OPENPROJECT_HTTPS=false
  )

  if [[ -n "${PLATFORM}" ]]; then
    docker_run_args+=(--platform "${PLATFORM}")
  fi

  docker run "${docker_run_args[@]}" "${IMAGE}"

  while true; do
    if curl --silent --fail "${api_url}"; then
      break
    fi

    if (( SECONDS >= deadline )); then
      docker logs "${VALIDATION_CONTAINER_NAME}" --tail 400 || true
      die "Timed out waiting for ${api_url}"
    fi

    sleep 2
  done

  docker exec "${VALIDATION_CONTAINER_NAME}" sh -lc '
set -eu
command -v -- gosu >/dev/null 2>&1
gosu nobody true
[ -d /opt/hocuspocus ]
[ -x /usr/lib/postgresql/17/bin/psql ]
command -v -- node >/dev/null 2>&1
command -v -- npm >/dev/null 2>&1

secret="$(tr "\0" "\n" < /proc/1/environ | sed -n "s/^OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=//p" | head -n 1)"
[ -n "$secret" ]
case "$secret" in
  (*[!A-Za-z0-9]*)
    echo "Expected auto-generated hocuspocus secret to use YAML-safe alphanumeric characters only."
    exit 1
    ;;
esac
ps -ef | grep -F "/opt/hocuspocus" | grep -v grep >/dev/null 2>&1 || {
  echo "Expected bundled hocuspocus process to be running."
  exit 1
}
ps -ef | grep -F "/usr/bin/memcached" | grep -v grep >/dev/null 2>&1 || {
  echo "Expected memcached process to be running."
  exit 1
}
'

  if docker logs "${VALIDATION_CONTAINER_NAME}" 2>&1 | grep -q "gave up: hocuspocus entered FATAL state"; then
    docker logs "${VALIDATION_CONTAINER_NAME}" --tail 200 || true
    die "Bundled hocuspocus failed to start in all-in-one image."
  fi

  if docker logs "${VALIDATION_CONTAINER_NAME}" 2>&1 | grep -q "gave up: memcached entered FATAL state"; then
    docker logs "${VALIDATION_CONTAINER_NAME}" --tail 200 || true
    die "Bundled memcached failed to start in all-in-one image."
  fi
}

case "${TARGET}" in
  slim)
    log "Validating slim image (${IMAGE})"
    validate_slim
    ;;
  slim-bim)
    log "Validating slim-bim image (${IMAGE})"
    validate_slim_bim
    ;;
  all-in-one)
    log "Validating all-in-one image (${IMAGE})"
    validate_all_in_one
    ;;
  *)
    die "Unsupported target '${TARGET}'. Expected slim, slim-bim, or all-in-one."
    ;;
esac

log "Validation completed successfully for target '${TARGET}'."
