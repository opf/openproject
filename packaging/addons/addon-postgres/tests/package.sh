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
export APP_NAME=pg18-package-test APP_SAFE_NAME=openproject INSTALLER_DIR=/tmp/installer
mkdir -p "$INSTALLER_DIR"
cat > "$INSTALLER_DIR/wizard" <<'WIZARD'
wiz_get() {
  case "$1" in
    postgres/autoinstall) echo install ;;
    postgres/db_host) echo 127.0.0.1 ;;
    postgres/db_port) echo 45432 ;;
    postgres/db_name|postgres/db_username|postgres/db_password) echo openproject ;;
    *) return 1 ;;
  esac
}
wiz_fact() {
  case "$1" in
    osfamily) echo debian ;;
    osversion) echo 12 ;;
  esac
}
wiz_check_package() { dpkg-query -W "$1" >/dev/null 2>&1; }
wiz_set() { :; }
WIZARD
/source/bin/preinstall
test "$(PGPASSWORD=openproject psql -h 127.0.0.1 -p 45432 -U openproject -d openproject -v ON_ERROR_STOP=1 -tAc "SELECT count(*) FROM pg_available_extensions WHERE name = 'vector' AND installed_version IS NULL")" = 1
echo 'PASS: clean Debian 12 packaged installation'
