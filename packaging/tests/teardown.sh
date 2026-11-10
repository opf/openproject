#!/usr/bin/env bash

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

set -euo pipefail

teardown="$(cd "$(dirname "$0")/.." && pwd)/teardown"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

mkdir -p dependencies/{runtime,development}
printf '{"name":"runtime","version":"1.0.0"}\n' > dependencies/runtime/package.json
printf '{"name":"development","version":"1.0.0"}\n' > dependencies/development/package.json
cat > package.json <<'JSON'
{
  "name": "packaging-cleanup-test",
  "version": "1.0.0",
  "dependencies": { "runtime": "file:dependencies/runtime" },
  "devDependencies": { "development": "file:dependencies/development" },
  "scripts": { "postinstall": "touch unexpected-postinstall" }
}
JSON

export NPM_CONFIG_PRODUCTION=false
export npm_config_cache="$tmpdir/npm-cache"
npm install --ignore-scripts --offline --no-audit --no-fund
test -e node_modules/development/package.json

removed=(
  frontend/node_modules/dependency/index.js
  frontend/.angular/cache/file
  docs/user\ guide/index.md
  spec/fixtures/file
  modules/example/spec/fixture
  modules/example/test/fixture
  modules/example/tests/fixture
  public/assets/frontend/main.js.map
)
retained=(
  frontend/src/main.ts
  frontend/src/vendor/editor.js.map
  frontend/package.json
  docs/api/openapi.yml
  app/assets/videos/enterprise/demo.mp4
  public/assets/enterprise/demo-digest.mp4
  public/assets/frontend/main.js
  public/assets/.sprockets-manifest.json
  modules/example/app/models/model.rb
  modules/example/files/seed.bcf
  lookbook/previews/example.rb
  vendor/bim/converter.zip
  public/fonts/font.ttf
)
for path in "${removed[@]}" "${retained[@]}"; do
  mkdir -p "$(dirname "$path")"
  printf 'fixture\n' > "$path"
done

for run in 1 2; do
  echo "Cleanup pass $run"
  bash "$teardown"
  for path in "${removed[@]}"; do
    test ! -e "$path" || { echo "Unexpected file after cleanup: $path" >&2; exit 1; }
  done
  for path in "${retained[@]}"; do
    test "$(cat "$path")" = fixture
  done
  test -e node_modules/runtime/package.json
  test ! -e node_modules/development
  test ! -e unexpected-postinstall
done

echo "PASS: packaging cleanup preserves runtime and asset rebuild inputs"
