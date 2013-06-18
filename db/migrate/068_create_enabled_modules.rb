#-- encoding: UTF-8
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

class CreateEnabledModules < ActiveRecord::Migration
  def self.up
    create_table :enabled_modules do |t|
      t.column :project_id, :integer
      t.column :name, :string, :null => false
    end
    add_index :enabled_modules, [:project_id], :name => :enabled_modules_project_id

    # Enable all modules for existing projects
    Project.find(:all).each do |project|
      project.enabled_module_names = Redmine::AccessControl.available_project_modules
    end
  end

  def self.down
    drop_table :enabled_modules
  end
end
