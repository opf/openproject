#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

def deprecated_task(name, new_name)
  task name => new_name do
    $stderr.puts "\nNote: The rake task #{name} has been deprecated, please use the replacement version #{new_name}"
  end
end

def removed_task(name, message)
  task name do
    $stderr.puts "\nError: The rake task #{name} has been removed. #{message}"
    raise
  end
end

deprecated_task :load_default_data, 'redmine:load_default_data'

plugin_migrate_message = '<plugin>:install:migrations is used now to copy' +
                         ' migrations to the rails application directory.' +
                         ' After installation, use db:migrate.'
removed_task 'db:migrate_plugins', plugin_migrate_message
removed_task 'db:migrate:plugin', plugin_migrate_message
removed_task 'redmine:plugins:migrate', plugin_migrate_message
