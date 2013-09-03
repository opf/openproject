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

class MovePlanningElementTypesToLegacyPlanningElementTypes < ActiveRecord::Migration
  def up
    rename_table :default_planning_element_types, :legacy_default_planning_element_types
    rename_table :enabled_planning_element_types, :legacy_enabled_planning_element_types
    rename_table :planning_element_types,         :legacy_planning_element_types

    remove_column :work_packages, :planning_element_type_id
  end

  def down
    rename_table :legacy_default_planning_element_types, :default_planning_element_types
    rename_table :legacy_enabled_planning_element_types, :enabled_planning_element_types
    rename_table :legacy_planning_element_types,         :planning_element_types

    add_column :work_packages, :planning_element_type_id, :integer
  end
end
