#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class JoinTableForActiveActivities < ActiveRecord::Migration[6.0]
  class ActivitiesJoinTable < ApplicationRecord
    self.table_name = :time_entry_activities_projects
  end

  class TimeEntryActivity < ApplicationRecord
    self.table_name = :enumerations
  end

  def up
    create_join_table
    delete_invalid_project_activities
    link_time_entries_to_root_activities
    fill_new_join_table
    delete_inherited_activities
  end

  def down
    create_project_specific_activities
    link_time_entries_to_project_activities

    drop_table :time_entry_activities_projects
  end

  def create_join_table
    create_table :time_entry_activities_projects do |t|
      t.references :activity, null: false, foreign_key: { to_table: :enumerations }, index: true
      t.references :project, null: false, foreign_key: true, index: true
      t.boolean :active, default: true, index: true
    end
    add_index :time_entry_activities_projects,
              %i[project_id activity_id],
              unique: true,
              name: "index_teap_on_project_id_and_activity_id"
  end

  # Delete all references from enumerations to projects which point to no longer
  # existing projects.
  def delete_invalid_project_activities
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        DELETE FROM enumerations
        USING enumerations AS enums
        LEFT OUTER JOIN projects on enums.project_id = projects.id
        WHERE enums.id = enumerations.id AND enums.type = 'TimeEntryActivity' AND projects.id IS NULL AND enums.project_id IS NOT NULL
      SQL
    )
  end

  def link_time_entries_to_root_activities
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        UPDATE
          time_entries te_sink
        SET
          activity_id = enumerations.parent_id
        FROM
          time_entries te_source
        INNER JOIN enumerations ON te_source.activity_id = enumerations.id AND enumerations.parent_id IS NOT NULL AND enumerations.type = 'TimeEntryActivity'
        WHERE
          te_sink.id = te_source.id
      SQL
    )
  end

  def link_time_entries_to_project_activities
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        UPDATE
         time_entries te_sink
        SET
          activity_id = COALESCE(child.id, root.id)
        FROM
          time_entries te_source
        INNER JOIN enumerations root ON te_source.activity_id = root.id AND root.type = 'TimeEntryActivity'
        LEFT OUTER JOIN enumerations child ON child.parent_id = root.id
        WHERE
          te_source.id = te_sink.id
    SQL
    )
  end

  def fill_new_join_table
    values = TimeEntryActivity
             .where
             .not(parent_id: nil)
             .pluck(:project_id, :parent_id, :active)
             .map { |project_id, parent_id, active| { project_id:, activity_id: parent_id, active: } }

    ActivitiesJoinTable.insert_all(values) if values.present?
  end

  def delete_inherited_activities
    TimeEntryActivity.where.not(parent_id: nil).delete_all
  end

  def create_project_specific_activities
    ActiveRecord::Base.connection.exec_query(
      <<-SQL.squish
        INSERT INTO enumerations (name, is_default, type, position, parent_id, project_id, active, created_at, updated_at)
        SELECT
          tea.name,
          false,
          tea.type,
          tea.position,
          teap.activity_id,
          teap.project_id,
          teap.active,
          NOW(),
          NOW()
        FROM time_entry_activities_projects teap
        JOIN enumerations tea ON tea.id = teap.activity_id AND tea.type = 'TimeEntryActivity'
      SQL
    )
  end
end
