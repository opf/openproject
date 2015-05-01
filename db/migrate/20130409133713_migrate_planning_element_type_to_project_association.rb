#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

class MigratePlanningElementTypeToProjectAssociation < ActiveRecord::Migration
  {
    DefaultPlanningElementType: 'timelines_default_planning_element_types',
    EnabledPlanningElementType: 'timelines_enabled_planning_element_types',
    PlanningElementType: 'timelines_planning_element_types',
    Project: 'projects',
    ProjectType: 'timelines_project_types'
  }.each do |class_name, table_name|
    const_set(class_name, Class.new(ActiveRecord::Base) do
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

      DefaultPlanningElementType.create!(project_type_id:          project_type.id,
                                         planning_element_type_id: planning_element_type.id)

      Project.find(:all, conditions: { timelines_project_type_id: project_type.id }).each do |project|
        EnabledPlanningElementType.create!(project_id:               project.id,
                                           planning_element_type_id: planning_element_type.id)
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
