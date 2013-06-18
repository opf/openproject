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

class CreateTimelinesDefaultPlanningElementTypes < ActiveRecord::Migration
  def self.up
    create_table :timelines_default_planning_element_types do |t|
      t.belongs_to :project_type
      t.belongs_to :planning_element_type

      t.timestamps
    end

    add_index :timelines_default_planning_element_types, :project_type_id, :name => "index_default_pe_types_on_project_type_id"
    add_index :timelines_default_planning_element_types, :planning_element_type_id, :name => "index_default_pe_types_on_pe_type_id"

  end

  def self.down
    drop_table :timelines_default_planning_element_types
  end
end
