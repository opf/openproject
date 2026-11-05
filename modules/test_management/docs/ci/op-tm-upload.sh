#!/usr/bin/env bash
# Upload a test report to OpenProject Test Management.
# POST /api/v3/projects/<project>/test_management/automation/results (multipart)
#
# Required: OP_URL OP_API_TOKEN OP_PROJECT OP_REPORT
# Optional: OP_FORMAT OP_MODE OP_TARGET_RUN OP_RUN_ID OP_ITERATION_ID OP_EXTERNAL_REF
#           OP_RUN_NAME OP_CLOSE_RUN OP_CASE_MATCHER OP_AUTO_CREATE OP_CA_CERT OP_AUTH
set -euo pipefail

die() { echo "op-tm-upload: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "'$1' is required"; }
truthy() { case "${1:-}" in true|1|yes|on) return 0 ;; *) return 1 ;; esac; }

need curl; need jq
: "${OP_URL:?OP_URL is required}"; : "${OP_API_TOKEN:?OP_API_TOKEN is required}"
: "${OP_PROJECT:?OP_PROJECT is required}"; : "${OP_REPORT:?OP_REPORT is required}"
[ -f "$OP_REPORT" ] || die "report not found: $OP_REPORT"

provider="" repository="" run_url="" sha="" branch="" workflow="" run_number="" attempt="" actor="" pr=""
if [ -n "${GITHUB_ACTIONS:-}" ]; then
  provider=github; repository="${GITHUB_REPOSITORY:-}"
  run_url="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  sha="${GITHUB_SHA:-}"; branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"; workflow="${GITHUB_WORKFLOW:-}"
  run_number="${GITHUB_RUN_NUMBER:-}"; attempt="${GITHUB_RUN_ATTEMPT:-1}"; actor="${GITHUB_ACTOR:-}"
  if [ "${GITHUB_EVENT_NAME:-}" = pull_request ] && [ -n "${GITHUB_REF:-}" ]; then pr="$(echo "$GITHUB_REF" | cut -d/ -f3)"; fi
  : "${OP_EXTERNAL_REF:=github:${GITHUB_REPOSITORY}:${GITHUB_RUN_ID}:${attempt}}"
fi

metadata=$(jq -n \
  --arg provider "$provider" --arg repository "$repository" --arg runUrl "$run_url" \
  --arg sha "$sha" --arg branch "$branch" --arg workflow "$workflow" \
  --arg runNumber "$run_number" --arg attempt "$attempt" --arg actor "$actor" --arg pr "$pr" \
  --arg format "${OP_FORMAT:-auto}" --arg mode "${OP_MODE:-}" --arg targetRun "${OP_TARGET_RUN:-}" \
  --arg runName "${OP_RUN_NAME:-}" --arg caseMatcher "${OP_CASE_MATCHER:-auto}" \
  --argjson closeRun "$(truthy "${OP_CLOSE_RUN:-}" && echo true || echo false)" \
  --argjson createMissing "$(truthy "${OP_AUTO_CREATE:-}" && echo true || echo false)" \
  --argjson runId "${OP_RUN_ID:-null}" --argjson iterationId "${OP_ITERATION_ID:-null}" \
  --arg externalRef "${OP_EXTERNAL_REF:-}" \
  '{
     format: $format, caseMatcher: $caseMatcher, createMissing: $createMissing, closeRun: $closeRun
   }
   + (if $mode != "" then {mode: $mode} else {} end)
   + (if $targetRun != "" then {targetRun: $targetRun} else {} end)
   + (if $runName != "" then {name: $runName} else {} end)
   + (if $externalRef != "" then {externalRef: $externalRef} else {} end)
   + (if $runId != null then {runId: $runId} else {} end)
   + (if $iterationId != null then {iterationId: $iterationId} else {} end)
   + (if $provider != "" then {ci: {
        provider: $provider, repository: $repository, runUrl: $runUrl, commitSha: $sha,
        branch: $branch, workflow: $workflow, runNumber: $runNumber, attempt: $attempt,
        actor: $actor, pullRequest: (if $pr == "" then null else $pr end)
      }} else {} end)')

url="${OP_URL%/}/api/v3/projects/${OP_PROJECT}/test_management/automation/results"
auth=(-H "Authorization: Bearer ${OP_API_TOKEN}")
case "${OP_AUTH:-bearer}" in
  basic) auth=(-u "apikey:${OP_API_TOKEN}") ;;
esac
curl_opts=()
[ -n "${OP_CA_CERT:-}" ] && curl_opts+=(--cacert "$OP_CA_CERT")

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
code=$(curl -sS "${curl_opts[@]}" "${auth[@]}" -o "$tmp" -w "%{http_code}" \
  -F "report=@${OP_REPORT}" -F "metadata=${metadata};type=application/json" "$url")
cat "$tmp"
echo
[[ "$code" =~ ^2 ]] || die "HTTP $code"
