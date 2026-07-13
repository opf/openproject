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

# Compares the major version of the Hocuspocus client (@hocuspocus/provider, in
# the frontend) against the server (@hocuspocus/server, in the op-blocknote-hocuspocus
# extension). The client ships with the core app; the server ships as the separately
# built and deployed openproject/hocuspocus image, and the two live in separate
# dependabot ecosystems that can never be grouped — so they bump independently and
# can silently drift. This flags a major mismatch for human review. It never fails
# the build: Hocuspocus supports a one-major skew in both directions, so a mismatch
# is a heads-up, not a blocker.

set -e

PROVIDER_RANGE=$(jq -r '.dependencies["@hocuspocus/provider"] // empty' frontend/package.json)
SERVER_RANGE=$(jq -r '.dependencies["@hocuspocus/server"] // empty' extensions/op-blocknote-hocuspocus/package.json)

if [ -z "$PROVIDER_RANGE" ] || [ -z "$SERVER_RANGE" ]; then
  echo "::warning::Could not read @hocuspocus/provider or @hocuspocus/server version; skipping skew check."
  exit 0
fi

# Strip a leading range operator (^, ~, >=, etc.) and take the major version.
major() {
  echo "$1" | sed -E 's/^[^0-9]*//' | cut -d. -f1
}

PROVIDER_MAJOR=$(major "$PROVIDER_RANGE")
SERVER_MAJOR=$(major "$SERVER_RANGE")

echo "@hocuspocus/provider (client): ${PROVIDER_RANGE} (major ${PROVIDER_MAJOR})"
echo "@hocuspocus/server (server):   ${SERVER_RANGE} (major ${SERVER_MAJOR})"

{
  echo "provider_range=${PROVIDER_RANGE}"
  echo "server_range=${SERVER_RANGE}"
  echo "provider_major=${PROVIDER_MAJOR}"
  echo "server_major=${SERVER_MAJOR}"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"

if [ "$PROVIDER_MAJOR" != "$SERVER_MAJOR" ]; then
  echo "Major version skew detected between Hocuspocus client and server."
  echo "skew=true" >> "${GITHUB_OUTPUT:-/dev/stdout}"
else
  echo "Hocuspocus client and server are on the same major version."
  echo "skew=false" >> "${GITHUB_OUTPUT:-/dev/stdout}"
fi
