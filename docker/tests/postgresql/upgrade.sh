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

set -euo pipefail
for checksums in off on; do
  export PGDATA=/var/lib/postgresql/test-$checksums
  export PGUSER=postgres PGPASSWORD=postgres OPENPROJECT_INSTALLATION__TYPE=docker
  mkdir -p "$PGDATA" "$PGDATA-next"
  flags=()
  [ "$checksums" = off ] || flags+=(--data-checksums)
  PGBIN=/usr/lib/postgresql/17/bin /source/docker/prod/postgres-db-init "${flags[@]}"
  runuser -u postgres -- /usr/lib/postgresql/17/bin/pg_ctl -D "$PGDATA" -l /tmp/pg17.log -w start
  runuser -u postgres -- /usr/lib/postgresql/17/bin/psql -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION vector;
CREATE TABLE upgrade_test (embedding vector(3));
INSERT INTO upgrade_test VALUES ('[1,2,3]');
SQL
  runuser -u postgres -- /usr/lib/postgresql/17/bin/pg_ctl -D "$PGDATA" -m fast -w stop
  /source/docker/prod/postgres-db-upgrade
  runuser -u postgres -- /usr/lib/postgresql/18/bin/pg_ctl -D "$PGDATA-next" -l /tmp/pg18.log -w start
  test "$(runuser -u postgres -- psql -tAc "SELECT embedding <-> '[1,2,3]' FROM upgrade_test")" = 0
  test "$(runuser -u postgres -- psql -tAc 'SHOW data_checksums')" = "$checksums"
  runuser -u postgres -- /usr/lib/postgresql/18/bin/pg_ctl -D "$PGDATA-next" -m fast -w stop
  test "$(cat "$PGDATA/PG_VERSION")" = 17
  echo "PASS: upgrade with checksums $checksums"
done
