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

class RemoveProjectTypeIdFromTimelinesPlanningElementTypes < ActiveRecord::Migration
  def self.up
    change_table(:timelines_planning_element_types) do |t|
      t.remove :project_type_id
    end
  end

  def self.down
    change_table(:timelines_planning_element_types) do |t|
      t.belongs_to :project_type
    end
    add_index :timelines_planning_element_types, :project_type_id
  end
end
