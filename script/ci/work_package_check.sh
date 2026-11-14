#!/bin/bash
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

set -e

# script/ci/work_package_check.sh

# Read from the PR_BODY / PR_TITLE environment variables, falling back to
# positional arguments so the script can still be run manually for testing.
PR_BODY="${PR_BODY:-$1}"
PR_TITLE="${PR_TITLE:-$2}"

# Collect every work package URL mentioned in the PR description.
# IDs can be numeric (e.g. 12345) or semantic (e.g. SC-123: an uppercase prefix, a dash, then a number).
WP_URLS=$(echo "$PR_BODY" | grep -oE 'https://community.openproject.org/(wp|work_packages|projects/[^/]+/work_packages)/([A-Z][A-Z0-9_]*-[0-9]+|[0-9]+)/?' || true)

if [ -z "$WP_URLS" ]; then
  # Fall back to an ID in square brackets in the PR title, e.g. [OP-19205] My title here
  TITLE_ID=$(echo "$PR_TITLE" | grep -oE '\[([A-Z][A-Z0-9_]*-[0-9]+|[0-9]+)\]' | head -n 1 | tr -d '[]' || true)
  if [ -n "$TITLE_ID" ]; then
    WP_URLS="https://community.openproject.org/wp/${TITLE_ID}"
  fi
fi

if [ -z "$WP_URLS" ]; then
  echo "::warning::PR description does not contain a valid URL to an OpenProject ticket, nor a [ID] in the title."
  echo "no_ticket=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Extract version from the Ruby file. Every work package is checked against it.
VERSION_FROM_FILE=$(ruby -e 'require_relative "./lib/open_project/version"; puts OpenProject::VERSION.to_s')
echo "Version from file: $VERSION_FROM_FILE"

WP_COUNT=$(printf '%s\n' "$WP_URLS" | grep -c '[^[:space:]]' || true)

VERSION_MISMATCH_DETAILS=""
ENTERPRISE_MISSING_DETAILS=""
FROZEN_RELEASE_FEATURE_DETAILS=""
ANY_BEHIND_FLAG=false

while IFS= read -r WP_URL; do
  [ -n "$WP_URL" ] || continue

  # Extract the work package ID (last path segment, numeric or semantic; ignore any trailing slash)
  WORK_PACKAGE_ID=$(echo "${WP_URL%/}" | grep -oE '[^/]+$')
  echo "Work Package ID: $WORK_PACKAGE_ID"

  API_URL="https://community.openproject.org/api/v3/work_packages/${WORK_PACKAGE_ID}"
  HTTP_STATUS=$(curl -s -w "%{http_code}" -o response.json "$API_URL")

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "::warning::API request for work package ${WORK_PACKAGE_ID} failed with status code $HTTP_STATUS. Skipping."
    cat response.json || true
    continue
  fi

  TYPE_FROM_API=$(jq -r '._links.type.title // "not set"' response.json)

  if [[ "$TYPE_FROM_API" =~ ^(Feature|Epic)$ && "$BASE_REF" == release/* && " $UNFROZEN_RELEASE_BRANCHES " != *" $BASE_REF "* ]]; then
    echo "::warning::Work package ${WORK_PACKAGE_ID} is a ${TYPE_FROM_API} and targets the frozen release branch ${BASE_REF}."
    FROZEN_RELEASE_FEATURE_DETAILS+=" - ${WP_URL}"$'\n'
  fi

  # Extract and compare the versions from the api response.
  # Since 17.8., we are using targetVersions as the linked field. It may contain multiple references.
  # We still fall back to the version.title for now.
  VERSIONS_FROM_API=$(jq -r '
    def target_version_titles:
      if (._links.targetVersions? | type) == "array" then
        [._links.targetVersions[]?.title // empty]
      else
        []
      end;

    (target_version_titles) as $target_versions |
    if ($target_versions | length) > 0 then
      $target_versions[]
    elif ._links.version.title? then
      ._links.version.title
    else
      empty
    end
  ' response.json)

  if [ -z "$VERSIONS_FROM_API" ]; then
    VERSIONS_FROM_API="not set"
  fi

  echo "Versions from API:"
  while IFS= read -r VERSION_FROM_API; do
    echo " - ${VERSION_FROM_API}"
  done <<< "$VERSIONS_FROM_API"

  if printf '%s\n' "$VERSIONS_FROM_API" | grep -Fxq "Behind feature flag"; then
    echo "Work package ${WORK_PACKAGE_ID} is assigned to \"Behind feature flag\". Skipping checks."
    ANY_BEHIND_FLAG=true
    continue
  fi

  # Compare the versions
  if ! printf '%s\n' "$VERSIONS_FROM_API" | grep -Fxq "$VERSION_FROM_FILE"; then
    echo "Version mismatch detected for work package ${WORK_PACKAGE_ID}."
    WP_VERSIONS_FROM_API=$(printf '%s\n' "$VERSIONS_FROM_API" | paste -sd ',' -)
    VERSION_MISMATCH_DETAILS+=" - ${WP_URL} (work package version: ${WP_VERSIONS_FROM_API})"$'\n'
    MISMATCH_WP_URL="$WP_URL"
    MISMATCH_WP_VERSIONS="$WP_VERSIONS_FROM_API"
  else
    echo "One of the target versions from the work package ${WORK_PACKAGE_ID} matches the version in the version file this PR targets."
  fi

  # Extract and check the presence of an Enterprise plan field from the api response
  ENTERPRISE_PLAN_FROM_API=$(jq -r '._links.customField426.title // "not set"' response.json)

  if [[ ! "$TYPE_FROM_API" =~ ^(Feature|Epic)$ ]]; then
    echo "Work package with type $TYPE_FROM_API does not require an Enterprise plan field to be set."
  elif [ "$ENTERPRISE_PLAN_FROM_API" = "not set" ]; then
    echo "::warning::Enterprise plan field is not set for work package ${WORK_PACKAGE_ID}."
    ENTERPRISE_MISSING_DETAILS+=" - ${WP_URL}"$'\n'
    ENTERPRISE_MISSING_WP_URL="$WP_URL"
  else
    echo "Enterprise Plan is set to ${ENTERPRISE_PLAN_FROM_API} for the work package ${WORK_PACKAGE_ID}."
  fi
done <<< "$WP_URLS"

# When a single work package is linked (the common case) emit the legacy single-value
# outputs so the PR comments read exactly as before. Only aggregate for multiple.
if [ "$WP_COUNT" -eq 1 ]; then
  echo "single_wp=true" >> "$GITHUB_OUTPUT"
fi

if [ -n "$VERSION_MISMATCH_DETAILS" ]; then
  echo "version_mismatch=true" >> "$GITHUB_OUTPUT"
  echo "core_version=${VERSION_FROM_FILE}" >> "$GITHUB_OUTPUT"
  if [ "$WP_COUNT" -eq 1 ]; then
    echo "wp_url=${MISMATCH_WP_URL}" >> "$GITHUB_OUTPUT"
    echo "wp_version=${MISMATCH_WP_VERSIONS}" >> "$GITHUB_OUTPUT"
  else
    {
      echo "version_mismatch_details<<WP_EOF"
      printf '%s' "$VERSION_MISMATCH_DETAILS"
      echo "WP_EOF"
    } >> "$GITHUB_OUTPUT"
  fi
fi

if [ -n "$ENTERPRISE_MISSING_DETAILS" ]; then
  echo "enterprise_plan_missing=true" >> "$GITHUB_OUTPUT"
  if [ "$WP_COUNT" -eq 1 ]; then
    echo "wp_url=${ENTERPRISE_MISSING_WP_URL}" >> "$GITHUB_OUTPUT"
  else
    {
      echo "enterprise_missing_details<<WP_EOF"
      printf '%s' "$ENTERPRISE_MISSING_DETAILS"
      echo "WP_EOF"
    } >> "$GITHUB_OUTPUT"
  fi
fi

if [ -n "$FROZEN_RELEASE_FEATURE_DETAILS" ]; then
  echo "frozen_release_feature=true" >> "$GITHUB_OUTPUT"
  {
    echo "frozen_release_feature_details<<WP_EOF"
    printf '%s' "$FROZEN_RELEASE_FEATURE_DETAILS"
    echo "WP_EOF"
  } >> "$GITHUB_OUTPUT"
fi

# Only report behind_feature_flag when it is the sole reason the version check did
# not run; a real mismatch on another work package must still surface.
if [ -z "$VERSION_MISMATCH_DETAILS" ] && [ "$ANY_BEHIND_FLAG" = true ]; then
  echo "behind_feature_flag=true" >> "$GITHUB_OUTPUT"
fi
