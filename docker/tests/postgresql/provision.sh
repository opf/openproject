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
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT '[1,2,3]'::vector <-> '[1,2,3]'::vector;"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'DROP EXTENSION vector;'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
/source/docker/prod/supervisord
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -o "-c config_file=$PGCONF_FILE" -l /tmp/aio.log -w start
test "$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_extension WHERE extname = 'vector'")" = 0
echo 'PASS: fresh AIO activates vector; existing AIO is unchanged'

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
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'DROP EXTENSION vector;'
echo 'PASS: explicit PostgreSQL 17 pin starts an existing cluster'

export INSTALLER_DIR=/tmp/installer APP_NAME=pg18-test APP_SAFE_NAME=openproject
mkdir -p "$INSTALLER_DIR" "/etc/$APP_NAME/conf.d"
touch "/etc/$APP_NAME/conf.d/00_addon_postgres"
cat > "$INSTALLER_DIR/wizard" <<'WIZARD'
wiz_get() {
  case "$1" in
    postgres/autoinstall) echo install ;;
    postgres/db_host) echo 127.0.0.1 ;;
    postgres/db_port) echo 5432 ;;
    postgres/db_name|postgres/db_username|postgres/db_password) echo openproject ;;
    *) return 1 ;;
  esac
}
wiz_fact() { echo 'Unexpected package installation' >&2; exit 99; }
WIZARD
/source/packaging/addons/addon-postgres/bin/preinstall
test "$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_extension WHERE extname = 'vector'")" = 0
echo 'PASS: packaged reconfiguration checks connectivity without provisioning'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop

export PGDATA=/var/lib/postgresql/aio
export PGVERSION=18 PGBIN=/usr/lib/postgresql/18/bin PGCONF_FILE=/etc/postgresql/18/main/postgresql.conf
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -o "-c config_file=$PGCONF_FILE" -l /tmp/aio.log -w start
export APP_NAME=pg18-fresh APP_SAFE_NAME=packagedfresh
cat > "$INSTALLER_DIR/wizard" <<'WIZARD'
wiz_get() {
  case "$1" in
    postgres/autoinstall) echo install ;;
    postgres/addon_version) echo v1 ;;
    postgres/db_host) echo 127.0.0.1 ;;
    postgres/db_port) echo 5432 ;;
    postgres/db_name|postgres/db_username|postgres/db_password) echo packagedfresh ;;
    *) return 1 ;;
  esac
}
wiz_fact() {
  case "$1" in
    osfamily) echo debian ;;
    osversion) echo 12 ;;
  esac
}
wiz_check_package() { dpkg-query -W "$1" >/dev/null; }
wiz_set() { :; }
WIZARD
/source/packaging/addons/addon-postgres/bin/preinstall
PGPASSWORD=packagedfresh psql -h 127.0.0.1 -U packagedfresh -d packagedfresh -v ON_ERROR_STOP=1 -c "SELECT '[1,2,3]'::vector <-> '[1,2,3]'::vector;"
echo 'PASS: packaged provisioning activates vector in a new database'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
