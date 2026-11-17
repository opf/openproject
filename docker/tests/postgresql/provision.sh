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

export PGDATA=/var/lib/postgresql/aio
export PGVERSION=18 PGBIN=/usr/lib/postgresql/18/bin PGCONF_FILE=/etc/postgresql/18/main/postgresql.conf
export APP_PATH=/app DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
mkdir -p "$APP_PATH/docker/prod" "$PGDATA"
useradd -m app
cp /source/docker/prod/postgres-db-init "$APP_PATH/docker/prod/"
for script in migrate seeder; do
  printf '#!/bin/bash\nexit 0\n' > "$APP_PATH/docker/prod/$script"
  chmod +x "$APP_PATH/docker/prod/$script"
done
printf '#!/bin/bash\nexit 0\n' > /usr/bin/supervisord
printf '[supervisord]\n' > "$APP_PATH/docker/prod/supervisord.conf.erb"
cd "$APP_PATH"

echo 17 > "$PGDATA/PG_VERSION"
if /source/docker/prod/supervisord > /tmp/mismatch.log 2>&1; then
  echo 'Expected an AIO version mismatch failure'; exit 1
fi
grep -q 'PGVERSION=17' /tmp/mismatch.log
test "$(cat "$PGDATA/PG_VERSION")" = 17
test "$(find "$PGDATA" -type f | wc -l)" = 1
rm "$PGDATA/PG_VERSION"
/source/docker/prod/supervisord
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -o "-c config_file=$PGCONF_FILE" -l /tmp/aio.log -w start
test "$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector' AND installed_version IS NULL")" = 1
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
/source/docker/prod/supervisord
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -o "-c config_file=$PGCONF_FILE" -l /tmp/aio.log -w start
test "$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector' AND installed_version IS NULL")" = 1
echo 'PASS: fresh and existing AIO leave vector available for application migrations'

mkdir -p /var/lib/postgresql/external-marker
echo 17 > /var/lib/postgresql/external-marker/PG_VERSION
PGDATA=/var/lib/postgresql/external-marker DATABASE_URL=postgres://openproject:openproject@localhost/openproject /source/docker/prod/supervisord
test "$(cat /var/lib/postgresql/external-marker/PG_VERSION)" = 17
echo 'PASS: external database ignores unrelated local cluster version'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop

export PGVERSION=17 PGBIN=/usr/lib/postgresql/17/bin PGCONF_FILE=/etc/postgresql/17/main/postgresql.conf
export PGDATA=/var/lib/postgresql/aio17
/source/docker/prod/supervisord
/source/docker/prod/supervisord
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -o "-c config_file=$PGCONF_FILE" -l /tmp/aio17.log -w start
test "$(psql "$DATABASE_URL" -tAc 'SHOW server_version_num')" -lt 180000
test "$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector' AND installed_version IS NULL")" = 1
echo 'PASS: explicit PostgreSQL 17 pin starts an existing cluster'

runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
