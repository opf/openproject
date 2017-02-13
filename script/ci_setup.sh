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

# script/ci_setup.sh
#!/bin/sh

run() {
  echo $1;
  eval $1;
}

if [ $1 = "mysql" ]; then
  run "mysql -e 'create database travis_ci_test;'"
  run "cp script/templates/database.travis.mysql.yml config/database.yml"

elif [ $1 = "postgres" ]; then
  run "psql -c 'create database travis_ci_test;' -U postgres"
  run "cp script/templates/database.travis.postgres.yml config/database.yml"

fi

# run migrations for mysql or postgres
if [ $1 != '' ]; then
  run "bundle exec rake db:migrate"
fi

if [ $2 != *"spec"* ] && [ $2 != *"npm"* ]; then
  run "bundle exec rake assets:precompile"
fi
