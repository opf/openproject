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

class MigrateTimelinesEnumerations < ActiveRecord::Migration
  PROJECT_STATUS_TYPE_NAME = { 'Timelines::ReportedProjectStatus' => 'ReportedProjectStatus' }

  def up
    migrate_reported_project_statuses(PROJECT_STATUS_TYPE_NAME)
    remove_planning_element_statuses
  end

  def down
    migrate_reported_project_statuses(PROJECT_STATUS_TYPE_NAME.invert)
  end

  private

  def migrate_reported_project_statuses(project_status_type_name)
    project_status_type_name.each do |k, v|
      update <<-SQL
        UPDATE enumerations
        SET type = '#{v}'
        WHERE type = '#{k}';
      SQL
    end
  end

  def remove_planning_element_statuses
    delete <<-SQL
      DELETE FROM enumerations
      WHERE type = 'Timelines::PlanningElementStatus'
    SQL
  end
end
