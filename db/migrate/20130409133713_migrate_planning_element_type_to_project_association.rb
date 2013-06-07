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

class MigratePlanningElementTypeToProjectAssociation < ActiveRecord::Migration
  {
    :DefaultPlanningElementType => 'timelines_default_planning_element_types',
    :EnabledPlanningElementType => 'timelines_enabled_planning_element_types',
    :PlanningElementType        => 'timelines_planning_element_types',
    :Project                    => 'projects',
    :ProjectType                => 'timelines_project_types'
  }.each do |class_name, table_name|
    self.const_set(class_name, Class.new(ActiveRecord::Base) do
      self.table_name = table_name
    end)
  end

  def self.up
    DefaultPlanningElementType.delete_all
    EnabledPlanningElementType.delete_all

    PlanningElementType.all.each do |planning_element_type|
      # Ignore global planning element types. They are not associated with
      # anything.
      next unless planning_element_type.project_type_id.present?

      project_type = ProjectType.find(planning_element_type.project_type_id)

      DefaultPlanningElementType.create!(:project_type_id          => project_type.id,
                                        :planning_element_type_id => planning_element_type.id)

      Project.find(:all, :conditions => {:timelines_project_type_id => project_type.id}).each do |project|
        EnabledPlanningElementType.create!(:project_id               => project.id,
                                          :planning_element_type_id => planning_element_type.id)
      end
    end
  end

  def self.down
    # Chosing to not throw a AR::IrreversibleMigration since this would
    # hinder the default uninstall recommendations of ChiliProject plugins.
    #
    # Anyway - this migration is irreversible nonetheless. The new schema
    # allows associations, that cannot be expressed by the old one. Going past
    # this migration backwards in time, will lead to data loss.
    #
    #
    # raise ActiveRecord::IrreversibleMigration
  end
end
