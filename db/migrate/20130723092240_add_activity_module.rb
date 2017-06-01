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

class AddActivityModule < ActiveRecord::Migration[4.2]
  def up
    # activate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = ['activity'] | project.enabled_module_names
    end

    # add activity module from default settings
    # if the setting already exists
    if Setting.find_by(name: 'default_projects_modules')
      Setting['default_projects_modules'] = ['activity'] | Setting.default_projects_modules
    end
  end

  def down
    # deactivate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = project.enabled_module_names - ['activity']
    end

    # remove activity module from default settings
    # if the setting already exists
    if Setting.find_by(name: 'default_projects_modules')
      Setting['default_projects_modules'] = Setting.default_projects_modules - ['activity']
    end
  end
end
