#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class MigrateTimelinesEnumerations < ActiveRecord::Migration[4.2]
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
