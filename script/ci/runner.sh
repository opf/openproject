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


# script/ci/runner.sh
# $1 = TEST_SUITE
# $2 = GROUP_SIZE
# $3 = GROUP
# $4 = OPENPROJECT_EDITION

#!/bin/sh

set -e

# Use the current HEAD as input to the seed
export CI_SEED=$(git rev-parse HEAD | tr -d 'a-z' | cut -b 1-5 | tr -d '0')
# Do not assume to have the angular cli running to serve assets. They are provided
# by rails assets:precompile
export OPENPROJECT_CLI_PROXY=''

case "$1" in
        npm)
            cd frontend && npm run test
            ;;
        *)
            bundle exec rake parallel:$1 -- --group-number $2 --only-group $3 --seed $CI_SEED
esac
