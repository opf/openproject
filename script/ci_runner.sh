#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

# script/ci_runner.sh
#!/bin/sh

set -e

case "$TEST_SUITE" in
        npm)
            npm test
            ;;
        spec_legacy)
            echo "Preparing SCM test repositories for legacy specs"
            bundle exec rake test:scm:setup:all
            bundle exec rspec -I spec_legacy spec_legacy
            ;;
        cucumber)
            bundle exec rake parallel:cucumber
            ;;
        specs)
            bundle exec parallel_test --type rspec -n $GROUP_SIZE --only-group $GROUP --pattern '^spec/(?!features\/)' spec
            ;;
        features)
            bundle exec parallel_test --type rspec -n $GROUP_SIZE --only-group $GROUP --pattern '^spec\/features\/' spec
            ;;
        *)
            echo "Unknown TEST_SUITE $TEST_SUITE"
            exit 1
esac
