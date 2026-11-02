#!/usr/bin/env bash
# Upload a test report (Playwright JSON, JUnit XML or native JSON) and its artifacts
# to OpenProject Test Management.
#
#   POST /api/v3/projects/<project>/test_management/automation/results   (multipart)
#
# Required environment:
#   OP_URL          e.g. https://openproject.test
#   OP_API_TOKEN    API token of the uploading user (My account > Access tokens > API)
#   OP_PROJECT      project identifier or id
#   OP_REPORT       path to the report file
# Optional:
#   OP_FORMAT            auto | playwright_json | junit | native | allure | cucumber_json | cucumber_messages (default auto)
#   OP_MODE              new_run | new_iteration   (default: the matching CI connection's mode, else new_run)
#   OP_TARGET_RUN        run name for new_iteration, e.g. Smoke or Regression (created if missing)
#   OP_CONNECTION        CI connection name or id (default: detected from provider + repository)
#   OP_ITERATION_NAME    name of the iteration started by this upload (default from CI metadata)
#   OP_RUN_ID            add results to this run (else OP_EXTERNAL_REF / new run)
#   OP_ITERATION_ID      fill this iteration ("Run in CI" passes op_iteration_id / OP_ITERATION_ID)
#   OP_EXTERNAL_REF      reuse the run with this reference (shards, retries); GitHub default:
#                        github:<repo>:<run id>:<attempt>
#   OP_RUN_NAME          name of a new run
#   OP_CLOSE_RUN         true = complete the run after this upload    (default false)
#   OP_CASE_MATCHER      auto | property | reference | id | title     (default auto)
#   OP_AUTO_CREATE       true = create cases for unmatched tests      (default false)
#   OP_LABELS            comma-separated labels for created cases
#   OP_WORK_PACKAGES     comma-separated work package ids to link to a new run
#   OP_ARTIFACTS_DIR     directory with screenshots/traces/videos (e.g. test-results)
#   OP_ARTIFACTS_GLOB    find -name patterns, comma-separated (default *.png,*.jpg,*.webm,*.zip,*.txt,*.log)
#   OP_EXTRA_FILES       comma-separated files attached to the run (e.g. playwright-report.zip)
#   OP_MAX_FILES         max. number of artifacts (default 200, the server limit)
#   OP_CA_CERT           CA bundle that signed OpenProject's certificate (internal CA, k3d / mkcert)
#   OP_SERVER_URL        CI server URL sent as ci.serverUrl (default: CI_SERVER_URL, GITHUB_SERVER_URL,
#                        JENKINS_URL or CI_SYSTEM_URL); picks the connection to that server (self-hosted)
#   OP_TEST_TYPE         e2e | unit | integration | component | api | other: kind of the tests; e2e makes
#                        written references "<repo>/e2e:…" (default: the connection's e2e setting)
#   OP_AUTH              bearer | basic (basic sends apikey:<token>; default bearer)
#   OP_FAIL_ON_UNMATCHED true = exit 3 if tests could not be matched to cases
#   OP_DRY_RUN           true = print the request instead of sending it
#
# Exit codes: 0 ok · 1 usage/config · 2 HTTP error · 3 unmatched tests (OP_FAIL_ON_UNMATCHED)
set -euo pipefail

die() { echo "op-tm-upload: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is required"; }
truthy() { case "${1:-}" in true|1|yes|on) return 0 ;; *) return 1 ;; esac; }
csv_json() { # "a, b" -> ["a","b"]   (numbers stay strings unless $2=num)
  local IFS=','; local out=()
  for v in ${1:-}; do v="$(echo "$v" | xargs)"; [ -n "$v" ] && out+=("$v"); done
  if [ "${2:-}" = num ]; then printf '%s\n' "${out[@]+"${out[@]}"}" | jq -R 'select(length>0)|ltrimstr("#")|tonumber' | jq -s .
  else printf '%s\n' "${out[@]+"${out[@]}"}" | jq -R 'select(length>0)' | jq -s .; fi
}

need curl; need jq
: "${OP_URL:?OP_URL is required}"; : "${OP_API_TOKEN:?OP_API_TOKEN is required}"
: "${OP_PROJECT:?OP_PROJECT is required}"; : "${OP_REPORT:?OP_REPORT is required}"
[ -f "$OP_REPORT" ] || die "report not found: $OP_REPORT"

# CI metadata (GitHub Actions, Gitea / Forgejo / Codeberg Actions, GitLab CI, Jenkins, Woodpecker)
provider="" repository="" run_url="" sha="" branch="" workflow="" run_number="" attempt="" actor="" pr="" server_url=""
if [ -n "${FORGEJO_ACTIONS:-}" ] || [ -n "${GITEA_ACTIONS:-}" ]; then
  # GitHub-compatible variables; the run page URL uses the run number.
  server="${GITHUB_SERVER_URL:-}"; server="${server%/}"
  if [ -n "${FORGEJO_ACTIONS:-}" ]; then provider=forgejo; else provider=gitea; fi
  [ "$server" = "https://codeberg.org" ] && provider=codeberg
  server_url="$server"
  repository="${GITHUB_REPOSITORY:-}"; run_number="${GITHUB_RUN_NUMBER:-}"
  run_url="${server}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_NUMBER:-}"
  sha="${GITHUB_SHA:-}"; branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"; workflow="${GITHUB_WORKFLOW:-}"
  attempt="${GITHUB_RUN_ATTEMPT:-1}"; actor="${GITHUB_ACTOR:-}"
  : "${OP_EXTERNAL_REF:=${provider}:${GITHUB_REPOSITORY:-}:${GITHUB_RUN_ID:-${GITHUB_RUN_NUMBER:-}}:${attempt}}"
elif [ -n "${GITHUB_ACTIONS:-}" ]; then
  provider=github; repository="${GITHUB_REPOSITORY:-}"; server_url="${GITHUB_SERVER_URL:-https://github.com}"
  run_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  sha="${GITHUB_SHA:-}"; branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"; workflow="${GITHUB_WORKFLOW:-}"
  run_number="${GITHUB_RUN_NUMBER:-}"; attempt="${GITHUB_RUN_ATTEMPT:-1}"; actor="${GITHUB_ACTOR:-}"
  if [ "${GITHUB_EVENT_NAME:-}" = pull_request ] && [ -n "${GITHUB_REF:-}" ]; then pr="$(echo "$GITHUB_REF" | cut -d/ -f3)"; fi
  : "${OP_EXTERNAL_REF:=github:${GITHUB_REPOSITORY}:${GITHUB_RUN_ID}:${attempt}}"
elif [ -n "${GITLAB_CI:-}" ]; then
  # CI_SERVER_URL includes a relative URL root (https://host/gitlab) and a non-default port.
  provider=gitlab; repository="${CI_PROJECT_PATH:-}"; server_url="${CI_SERVER_URL:-}"
  run_url="${CI_PIPELINE_URL:-}"; sha="${CI_COMMIT_SHA:-}"; branch="${CI_COMMIT_REF_NAME:-}"
  workflow="${CI_PROJECT_PATH:-}"; run_number="${CI_PIPELINE_IID:-}"; actor="${GITLAB_USER_LOGIN:-}"
  pr="${CI_MERGE_REQUEST_IID:-}"
  : "${OP_EXTERNAL_REF:=gitlab:${CI_PROJECT_PATH:-}:${CI_PIPELINE_ID:-}}"
elif [ -n "${JENKINS_URL:-}" ] && [ -n "${BUILD_NUMBER:-}" ]; then
  # repository = job path (folder/job), as on a Jenkins CI connection.
  provider=jenkins; repository="${JOB_NAME:-}"; run_url="${BUILD_URL:-}"; sha="${GIT_COMMIT:-}"; server_url="${JENKINS_URL%/}"
  branch="${BRANCH_NAME:-${GIT_BRANCH:-}}"; branch="${branch#origin/}"; workflow="${JOB_NAME:-}"
  run_number="${BUILD_NUMBER:-}"; pr="${CHANGE_ID:-}"
  : "${OP_EXTERNAL_REF:=jenkins:${JOB_NAME:-}:${BUILD_NUMBER:-}}"
elif [ "${CI:-}" = woodpecker ]; then
  # A Woodpecker connection is keyed by the numeric repository id; set OP_CONNECTION when the
  # upload should be linked to it outside "Run in CI".
  provider=woodpecker; repository="${CI_REPO:-}"; run_url="${CI_PIPELINE_URL:-}"; sha="${CI_COMMIT_SHA:-}"; server_url="${CI_SYSTEM_URL:-}"
  branch="${CI_COMMIT_SOURCE_BRANCH:-${CI_COMMIT_BRANCH:-}}"; workflow="${CI_WORKFLOW_NAME:-}"
  run_number="${CI_PIPELINE_NUMBER:-}"; actor="${CI_COMMIT_AUTHOR:-}"; pr="${CI_COMMIT_PULL_REQUEST:-}"
  : "${OP_EXTERNAL_REF:=woodpecker:${CI_REPO:-}:${CI_PIPELINE_NUMBER:-}}"
fi
server_url="${OP_SERVER_URL:-$server_url}"; server_url="${server_url%/}"

# Artifacts: relative paths are sent as attachmentPaths so equally named files
# (test-failed-1.png in every Playwright test folder) reach the right test.
max="${OP_MAX_FILES:-200}"
files=() paths=()
add_file() { [ -f "$1" ] || return 0; [ "${#files[@]}" -lt "$max" ] || { echo "op-tm-upload: more than $max artifacts, rest skipped" >&2; return 0; }; files+=("$1"); paths+=("${1#./}"); }
if [ -n "${OP_ARTIFACTS_DIR:-}" ] && [ -d "$OP_ARTIFACTS_DIR" ]; then
  IFS=',' read -r -a globs <<< "${OP_ARTIFACTS_GLOB:-*.png,*.jpg,*.jpeg,*.webm,*.zip,*.txt,*.log}"
  expr=(); for g in "${globs[@]}"; do g="$(echo "$g" | xargs)"; [ -n "$g" ] && expr+=(-o -name "$g"); done
  while IFS= read -r -d '' f; do add_file "$f"; done < <(find "$OP_ARTIFACTS_DIR" -type f \( "${expr[@]:1}" \) -print0 | sort -z)
fi
if [ -n "${OP_EXTRA_FILES:-}" ]; then
  IFS=',' read -r -a extra <<< "$OP_EXTRA_FILES"
  for f in "${extra[@]}"; do add_file "$(echo "$f" | xargs)"; done
fi

metadata="$(jq -n \
  --arg format "${OP_FORMAT:-auto}" --arg runId "${OP_RUN_ID:-}" --arg iterationId "${OP_ITERATION_ID:-}" --arg externalRef "${OP_EXTERNAL_REF:-}" \
  --arg runName "${OP_RUN_NAME:-}" --arg mode "${OP_MODE:-}" --arg targetRun "${OP_TARGET_RUN:-}" \
  --arg connection "${OP_CONNECTION:-}" --arg iterationName "${OP_ITERATION_NAME:-}" --arg caseMatcher "${OP_CASE_MATCHER:-auto}" \
  --argjson closeRun "$(truthy "${OP_CLOSE_RUN:-}" && echo true || echo false)" \
  --argjson autoCreate "$(truthy "${OP_AUTO_CREATE:-}" && echo true || echo false)" \
  --argjson labels "$(csv_json "${OP_LABELS:-}")" --argjson wps "$(csv_json "${OP_WORK_PACKAGES:-}" num)" \
  --argjson paths "$(printf '%s\n' "${paths[@]+"${paths[@]}"}" | jq -R 'select(length>0)' | jq -s .)" \
  --arg provider "$provider" --arg repository "$repository" --arg runUrl "$run_url" --arg commitSha "$sha" --arg branch "$branch" \
  --arg workflow "$workflow" --arg runNumber "$run_number" --arg runAttempt "$attempt" --arg actor "$actor" --arg pullRequest "$pr" \
  --arg serverUrl "$server_url" --arg testType "${OP_TEST_TYPE:-}" \
  '{format: $format, caseMatcher: $caseMatcher, closeRun: $closeRun, autoCreateCases: $autoCreate}
   + (if $runId != "" then {runId: ($runId|tonumber)} else {} end)
   + (if $iterationId != "" then {iterationId: ($iterationId|tonumber)} else {} end)
   + (if $externalRef != "" then {externalRef: $externalRef} else {} end)
   + (if $runName != "" then {runName: $runName} else {} end)
   + (if $mode != "" then {mode: $mode} else {} end)
   + (if $targetRun != "" then {targetRun: $targetRun} else {} end)
   + (if $connection != "" then {connection: $connection} else {} end)
   + (if $iterationName != "" then {iterationName: $iterationName} else {} end)
   + (if $testType != "" then {testType: $testType} else {} end)
   + (if ($labels|length) > 0 then {labels: $labels} else {} end)
   + (if ($wps|length) > 0 then {workPackageIds: $wps} else {} end)
   + (if ($paths|length) > 0 then {attachmentPaths: $paths} else {} end)
   + {ci: ({provider: $provider, repository: $repository, runUrl: $runUrl, commitSha: $commitSha, branch: $branch, workflow: $workflow,
            runNumber: $runNumber, runAttempt: $runAttempt, actor: $actor, pullRequest: $pullRequest, serverUrl: $serverUrl}
           | with_entries(select(.value != "")))}')"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
resp="$tmp/response.json"; printf '%s' "$metadata" > "$tmp/metadata.json"
url="${OP_URL%/}/api/v3/projects/${OP_PROJECT}/test_management/automation/results"
args=(--silent --show-error --retry 3 --max-time 600 -o "$resp" -w '%{http_code}')
if [ "${OP_AUTH:-bearer}" = basic ]; then args+=(-u "apikey:${OP_API_TOKEN}"); else args+=(-H "Authorization: Bearer ${OP_API_TOKEN}"); fi
[ -n "${OP_CA_CERT:-}" ] && args+=(--cacert "$OP_CA_CERT")
form=(-F "file=@\"${OP_REPORT}\"" -F "metadata=<${tmp}/metadata.json;type=application/json")
for f in "${files[@]+"${files[@]}"}"; do form+=(-F "attachments[]=@\"${f}\""); done

echo "op-tm-upload: ${OP_REPORT} + ${#files[@]} artifact(s) -> ${url}"
if truthy "${OP_DRY_RUN:-}"; then echo "$metadata" | jq .; exit 0; fi

status="$(curl "${args[@]}" "${form[@]}" "$url")" || { echo "op-tm-upload: request failed" >&2; exit 2; }
if [ "$status" != 200 ] && [ "$status" != 201 ]; then
  echo "op-tm-upload: HTTP $status" >&2
  jq -r '.message // .' "$resp" >&2 2>/dev/null || cat "$resp" >&2
  exit 2
fi

jq -r '"run \(.run.id) \"\(.run.name)\" (\(.run.state))\(if .createdRun then ", created" else "" end)\(if .replay then ", replay: nothing changed" else "" end)",
       (if .iteration then "iteration #\(.iteration.number) \"\(.iteration.name)\"\(if .createdIteration then ", started" else "" end) · mode \(.mode // "new_run")" else empty end),
       "parsed \(.import.parsedCount) · matched \(.import.matchedCount) · created \(.import.createdCasesCount) · unmatched \(.import.unmatchedCount) · attachments \(.import.attachmentsCount)",
       "pass rate \(.run.passRate)% · \(.run.statusCounts | to_entries | map("\(.key) \(.value)") | join(", "))",
       (.import.warnings[]? | "warning: \(.code) \(.fileName // .workPackageId // .connection // .name // "")"),
       (.import.unmatched[:20][]? | "unmatched (\(.reason)): \(.reference // .title)")' "$resp"
run_link="${OP_URL%/}/projects/${OP_PROJECT}/test_management/test_runs/$(jq -r .run.id "$resp")"
iter="$(jq -r '.iteration.number // empty' "$resp")"
if [ -n "$iter" ]; then run_link="${run_link}?iteration=${iter}"; fi
echo "op-tm-upload: ${run_link}"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  jq -r --arg link "$run_link" '"### OpenProject test run\n\n[\(.run.name)](\($link)) – \(.run.state)\(if .iteration then ", iteration #\(.iteration.number)" else "" end), pass rate \(.run.passRate)% (\(.import.matchedCount) matched, \(.import.unmatchedCount) unmatched)"' "$resp" >> "$GITHUB_STEP_SUMMARY"
fi
if truthy "${OP_FAIL_ON_UNMATCHED:-}" && [ "$(jq -r .import.unmatchedCount "$resp")" != 0 ]; then exit 3; fi
