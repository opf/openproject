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

PR_BODY="$@"

# Extract first work package URL from PR description
WP_URL=$(echo "$PR_BODY" | grep -oE 'https://community.openproject.org/(wp|work_packages|projects/[^/]+/work_packages)/[0-9]+' | head -n 1 || true)

if [ -z "$WP_URL" ]; then
  echo "::warning::PR description does not contain a valid URL to an OpenProject ticket."
  exit 0
fi

# Extract the work package ID
WORK_PACKAGE_ID=$(echo "$WP_URL" | grep -oE '[0-9]+$')
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
