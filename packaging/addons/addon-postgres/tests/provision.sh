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

export PGDATA=/var/lib/postgresql/addon17 PGBIN=/usr/lib/postgresql/17/bin
export DATABASE_URL=postgres://openproject:openproject@127.0.0.1/openproject
install -d -o postgres -g postgres "$PGDATA"
runuser -u postgres -- "$PGBIN/initdb" -D "$PGDATA" --auth=trust
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -l /tmp/addon17.log -w start
runuser -u postgres -- "$PGBIN/createuser" openproject
runuser -u postgres -- "$PGBIN/createdb" -O openproject openproject

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
/source/bin/preinstall
test "$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_extension WHERE extname = 'vector'")" = 0
echo 'PASS: packaged reconfiguration checks connectivity without provisioning'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop

export PGDATA=/var/lib/postgresql/addon18 PGBIN=/usr/lib/postgresql/18/bin
install -d -o postgres -g postgres "$PGDATA"
runuser -u postgres -- "$PGBIN/initdb" -D "$PGDATA" --auth=trust
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -l /tmp/addon18.log -w start
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
/source/bin/preinstall
test "$(PGPASSWORD=packagedfresh psql -h 127.0.0.1 -p 5432 -U packagedfresh -d packagedfresh -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector' AND installed_version IS NULL")" = 1
echo 'PASS: packaged provisioning leaves vector available for application migrations'
runuser -u postgres -- "$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
