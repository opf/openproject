#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RenameModulenameIssueTracking < ActiveRecord::Migration
  def up
    update <<-SQL
      UPDATE enabled_modules
      SET name = 'work_package_tracking'
      WHERE name = 'issue_tracking';
    SQL
    Setting['default_projects_modules'] = Setting['default_projects_modules'].map {|m| m.gsub("issue_tracking","work_package_tracking")}
  end

  def down
    update <<-SQL
      UPDATE enabled_modules
      SET name = 'issue_tracking'
      WHERE name = 'work_package_tracking';
    SQL
    Setting['default_projects_modules'] = Setting['default_projects_modules'].map {|m| m.gsub("work_package_tracking","issue_tracking")}
  end
end
