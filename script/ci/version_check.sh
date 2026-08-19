#!/bin/bash
#-- copyright
# OpenProject is a project management system.
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

set -e

# script/ci/version_check

# Read from the PR_BODY / PR_TITLE environment variables, falling back to
# positional arguments so the script can still be run manually for testing.
PR_BODY="${PR_BODY:-$1}"
PR_TITLE="${PR_TITLE:-$2}"

# Extract first work package URL from PR description.
# IDs can be numeric (e.g. 12345) or semantic (e.g. SC-123: an uppercase prefix, a dash, then a number).
WP_URL=$(echo "$PR_BODY" | grep -oE 'https://community.openproject.org/(wp|work_packages|projects/[^/]+/work_packages)/([A-Z][A-Z0-9_]*-[0-9]+|[0-9]+)/?' | head -n 1 || true)

if [ -n "$WP_URL" ]; then
  # Extract the work package ID (last path segment, numeric or semantic; ignore any trailing slash)
  WORK_PACKAGE_ID=$(echo "${WP_URL%/}" | grep -oE '[^/]+$')
else
  # Fall back to an ID in square brackets in the PR title, e.g. [OP-19205] My title here
  WORK_PACKAGE_ID=$(echo "$PR_TITLE" | grep -oE '\[([A-Z][A-Z0-9_]*-[0-9]+|[0-9]+)\]' | head -n 1 | tr -d '[]' || true)
  if [ -n "$WORK_PACKAGE_ID" ]; then
    WP_URL="https://community.openproject.org/wp/${WORK_PACKAGE_ID}"
  fi
fi

if [ -z "$WORK_PACKAGE_ID" ]; then
  echo "::warning::PR description does not contain a valid URL to an OpenProject ticket, nor a [ID] in the title."
  echo "no_ticket=true" >> "$GITHUB_OUTPUT"
  exit 0
fi
echo "Work Package ID: $WORK_PACKAGE_ID"

# Perform API request to fetch version
API_URL="https://community.openproject.org/api/v3/work_packages/${WORK_PACKAGE_ID}"
RESPONSE=$(curl -s -w "%{http_code}" -o response.json "$API_URL")
HTTP_STATUS=$(tail -n1 <<< "$RESPONSE")

if [ "$HTTP_STATUS" -ne 200 ]; then
  echo "API request failed with status code $HTTP_STATUS. Exiting."
  cat response.json
  exit 0
fi

VERSION_FROM_API=$(jq -r '._links.version.title // "not set"' response.json)
if [ -z "$VERSION_FROM_API" ]; then
  echo "::warning::Failed to extract version from API response."
  exit 0
fi

echo "Version from API: $VERSION_FROM_API"

# Extract version from the Ruby file using 'rake version'
VERSION_FROM_FILE=$(ruby -e 'require_relative "./lib/open_project/version"; puts OpenProject::VERSION.to_s')

echo "Version from file: $VERSION_FROM_FILE"

# Compare the versions
if [[ "$VERSION_FROM_API" != "$VERSION_FROM_FILE" ]]; then
  echo "Version mismatch detected."

  echo "version_mismatch=true" >> "$GITHUB_OUTPUT"
  echo "wp_url=${WP_URL}" >> "$GITHUB_OUTPUT"
  echo "wp_version=${VERSION_FROM_API}" >> "$GITHUB_OUTPUT"
  echo "core_version=${VERSION_FROM_FILE}" >> "$GITHUB_OUTPUT"
else
  echo "Version from the work package ${WORK_PACKAGE_ID} matches the version in the version file this PR targets."
fi
