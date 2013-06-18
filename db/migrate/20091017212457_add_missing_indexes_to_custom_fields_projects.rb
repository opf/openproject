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

class AddMissingIndexesToCustomFieldsProjects < ActiveRecord::Migration
  def self.up
    add_index :custom_fields_projects, [:custom_field_id, :project_id]
  end

  def self.down
    remove_index :custom_fields_projects, :column => [:custom_field_id, :project_id]
  end
end
