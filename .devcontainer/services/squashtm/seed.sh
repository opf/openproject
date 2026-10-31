#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"

SQUASH_HOST="squashtm"
SQUASH_URL="http://${SQUASH_HOST}:8080/squash"
API="${SQUASH_URL}/api/rest/latest"
AUTH=admin:admin

# curl hard-wires *.localhost to the loopback interface and ignores the system
# resolver, so pin the host to whatever the resolver (e.g. Docker DNS) returns.
SQUASH_IP=$(getent hosts "$SQUASH_HOST" | awk '{ print $1; exit }' || true)
[[ -n "$SQUASH_IP" ]] || { echo "Cannot resolve $SQUASH_HOST" >&2; exit 1; }
[[ "$SQUASH_IP" == *:* ]] && SQUASH_IP="[$SQUASH_IP]"
RESOLVE=(--resolve "${SQUASH_HOST}:443:${SQUASH_IP}")


#region Create project via UI

COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

xsrf_token() {
  awk '$6 == "XSRF-TOKEN" { print $7 }' "$COOKIES"
}

UI_CURL=(curl "${RESOLVE[@]}" -sS -b "$COOKIES" -c "$COOKIES")
CURL=(curl "${RESOLVE[@]}" -sS --fail-with-body -u "$AUTH" -H "Content-Type: application/json")

"${UI_CURL[@]}" --fail -o /dev/null "$SQUASH_URL/login"

"${UI_CURL[@]}" --fail-with-body \
  -H "X-XSRF-TOKEN: $(xsrf_token)" \
  --data-urlencode "username=${AUTH%%:*}" \
  --data-urlencode "password=${AUTH#*:}" \
  "$SQUASH_URL/backend/login" \
  | jq -e '.authenticated' > /dev/null || { echo "UI login failed" >&2; exit 1; }

RESPONSE=$(mktemp)
STATUS=$("${UI_CURL[@]}" -o "$RESPONSE" -w '%{http_code}' \
  -H "X-XSRF-TOKEN: $(xsrf_token)" \
  -H "Content-Type: application/json" \
  -d '{"name": "Integration Sandbox", "description": "", "label": "", "fromTemplate": false}' \
  "$SQUASH_URL/backend/projects/new")

if [[ "$STATUS" == 412 ]] && grep -q 'name-already-in-use' "$RESPONSE"; then
  echo "Project already exists"
  exit 0
elif [[ "$STATUS" != 2* ]]; then
  echo "Project creation failed (HTTP $STATUS):" >&2
  cat "$RESPONSE" >&2
  exit 1
fi
rm -f "$RESPONSE"

#endregion


# Project ID
PROJECT_ID=$("${CURL[@]}" "$API/projects" \
  | jq -r '._embedded.projects[] | select(.name == "Integration Sandbox") | .id')
echo "Project: $PROJECT_ID"

# Test cases
TC_IDS=()
declare -A TC_ID_BY_REFERENCE
for FILE in data/test-cases/*.json; do
  ID=$(jq --argjson id "$PROJECT_ID" '.parent = {_type: "project", id: $id}' "$FILE" \
    | "${CURL[@]}" -X POST "$API/test-cases" -d @- | jq -r .id)
  TC_IDS+=("$ID")
  TC_ID_BY_REFERENCE[$(jq -r .reference "$FILE")]=$ID
  echo "Test case: $ID ($FILE)"
done

# Requirements, verified by the test cases listed in "verified_by" (test case references)
for FILE in data/requirements/*.json; do
  ID=$(jq --argjson id "$PROJECT_ID" 'del(.verified_by) | .parent = {_type: "project", id: $id}' "$FILE" \
    | "${CURL[@]}" -X POST "$API/requirements" -d @- | jq -r .id)
  echo "Requirement: $ID ($FILE)"

  COVERING_IDS=()
  for REFERENCE in $(jq -r '.verified_by[]' "$FILE"); do
    COVERING_IDS+=("${TC_ID_BY_REFERENCE[$REFERENCE]}")
  done
  if (( ${#COVERING_IDS[@]} > 0 )); then
    "${CURL[@]}" -X POST "$API/requirements/$ID/coverages/$(IFS=,; echo "${COVERING_IDS[*]}")" > /dev/null
    echo "Coverage: requirement $ID verified by ${COVERING_IDS[*]}"
  fi
done

# Campaign
CAMPAIGN_ID=$(jq --argjson id "$PROJECT_ID" '.parent = {_type: "project", id: $id}' data/campaign.json \
  | "${CURL[@]}" -X POST "$API/campaigns" -d @- | jq -r .id)
echo "Campaign: $CAMPAIGN_ID"

# Iteration
ITERATION_ID=$(jq --argjson id "$CAMPAIGN_ID" '.parent = {_type: "campaign", id: $id}' data/iteration.json \
  | "${CURL[@]}" -X POST "$API/campaigns/$CAMPAIGN_ID/iterations" -d @- | jq -r .id)
echo "Iteration: $ITERATION_ID"

# Test plan: add each test case to the iteration
for TC in "${TC_IDS[@]}"; do
  "${CURL[@]}" -X POST "$API/iterations/$ITERATION_ID/test-plan" \
    -d '{"_type": "test-plan-item", "test_case": {"_type": "test-case", "id": '"$TC"'}}' > /dev/null
done
echo "Test plan: ${TC_IDS[*]} added"
