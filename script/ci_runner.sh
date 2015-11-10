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

# Usage:
#   sh script/ci_runner.sh spec 3 1
#
# Use
#   sh script/ci_runner.sh spec
# to make use of all available cores on the current machine. Most likely to
# be used on local dev machines.
#

# $1: type
# $2: group size
# $3: group number
run() {
  echo $1;
  eval $1;
  echo $2;
  eval $2;
  echo $3;
  eval $3;
}

if [ -n "$2" ] && [ -n "$3" ]; then
  GROUPING=" -n $2 --only-group $3"
else
  GROUPING=''
fi

if [ $1 = "npm" ]; then
  run "npm test"
else
  run "bundle exec rake parallel:$1 GROUP_SIZE=$2 GROUP=$3"
fi
