#!/bin/bash
set -eu

for container in app-web-1 app-worker-1 app-proxy-1; do
  if docker container inspect "${container}" >/dev/null 2>&1; then
    echo "::group::Runtime status: ${container}"
    docker inspect --format 'status={{.State.Status}} exit_code={{.State.ExitCode}} restarts={{.RestartCount}}' "${container}"
    docker logs --tail 200 "${container}" 2>&1 |
      grep -oE '[A-Z][A-Za-z_:]*(Error|Exception)|/app/(app|config|lib|modules|docker)/[A-Za-z0-9_./-]+:[0-9]+' |
      sort -u || true
    echo '::endgroup::'
  fi
done
