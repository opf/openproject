#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddActivityModule < ActiveRecord::Migration
  def up
    # activate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = ["activity"] | project.enabled_module_names
    end

    # add activity module from default settings
    Setting["default_projects_modules"] = ["activity"] | Setting.default_projects_modules
  end

  def down
    # deactivate activity module for all projects
    Project.all.each do |project|
      project.enabled_module_names = project.enabled_module_names - ["activity"]
    end

    # remove activity module from default settings
    Setting["default_projects_modules"] = Setting.default_projects_modules - ["activity"]
  end
end
