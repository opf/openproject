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

# Use the current HEAD as input to the seed
export CI_SEED=$(git rev-parse HEAD | tr -d 'a-z' | cut -b 1-5 | tr -d '0')

case "$TEST_SUITE" in
        npm)
            npm test
            ;;
        spec_legacy)
            echo "Preparing SCM test repositories for legacy specs"
            bundle exec rake test:scm:setup:all
            exec bundle exec rspec -I spec_legacy -o "--seed $CI_SEED" spec_legacy
            ;;
        specs)
            bin/parallel_test --type rspec -o "--seed $CI_SEED" -n $GROUP_SIZE --only-group $GROUP --pattern '^spec/(?!features\/)' spec
            ;;
        features)
            bin/parallel_test --type rspec -o "--seed $CI_SEED" -n $GROUP_SIZE --only-group $GROUP --pattern '^spec\/features\/' spec
            ;;
        *)
            bundle exec rake parallel:$TEST_SUITE
esac
