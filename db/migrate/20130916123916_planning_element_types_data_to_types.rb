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

require_relative 'migration_utils/utils'

class PlanningElementTypesDataToTypes < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    add_new_id_column

    add_pe_types_to_types

    add_workflow_for_former_pe_types

    enable_types_in_projects
  end

  def down
    remove_types_in_projects

    remove_workflow_for_former_pe_types

    remove_pe_types_from_types

    remove_new_id_column
  end

  private

  def add_new_id_column
    add_column :legacy_planning_element_types, :new_id, :integer
  end

  def add_pe_types_to_types
    say_with_time_silently 'Adding existing planning_element_types to types. Storing new id in legacy table.' do
      max_position = get_max_position

      return if max_position.blank?

      insert_legacy_types_into_types(max_position)

      add_new_id_to_legacy_table(max_position)
    end
  end

  def get_max_position
    max_position = select_all <<-SQL
      SELECT MAX(position) as max
      FROM #{db_types_table}
    SQL

    max_position.first['max']
  end

  def insert_legacy_types_into_types(max_position)
    execute <<-SQL
      INSERT INTO #{db_types_table}
      (
        name,
        in_aggregation,
        is_milestone,
        is_default,
        is_in_roadmap,
        position,
        color_id,
        created_at,
        updated_at
      )
      SELECT
        name,
        in_aggregation,
        is_milestone,
        is_default,
        #{quoted_false},
        position + #{max_position},
        color_id,
        created_at,
        updated_at
      FROM #{db_legacy_types_table}
      ORDER BY id ASC
    SQL
  end

  def add_new_id_to_legacy_table(max_position_existing_types)
    # Set the new_id column of every row in the
    # legacy_planning_element_types table
    # to be
    # * the value of the id column of the entry in the types
    # table
    # * that has a position that is equal to the
    # entry in the legacy_planning_element_types' position column minus
    # the maximum position that existed before
    #
    # Those are the new id values of the legacy_planning_element_types that
    # where just added as new types.
    execute <<-SQL
      UPDATE #{db_legacy_types_table}
      SET new_id = (SELECT #{db_types_table}.id
                    FROM #{db_types_table}
                    WHERE #{db_types_table}.position - #{max_position_existing_types} = #{db_legacy_types_table}.position)
    SQL
  end

  def add_workflow_for_former_pe_types
    say_with_time_silently 'Creating default workflows for migrated types' do
      all_status_ids = select_all <<-SQL
        SELECT id
        FROM #{db_status_table}
      SQL

      all_status_ids = all_status_ids.map { |s| s['id'] }

      # Select all roles
      # that are not builtin.
      # This prevents anonymous and non member roles to receive
      # workflows.
      all_role_ids = select_all <<-SQL
        SELECT id
        FROM #{db_roles_table}
        WHERE builtin = 0
      SQL

      all_role_ids = all_role_ids.map { |s| s['id'] }

      all_type_ids = select_all <<-SQL
        SELECT new_id
        FROM #{db_legacy_types_table}
      SQL

      all_type_ids = all_type_ids.map { |s| s['new_id'] }

      all_workflow_states = []

      all_role_ids.each do |role_id|
        all_type_ids.each do |type_id|
          all_status_ids.each do |status_a_id|
            all_status_ids.each do |status_b_id|
              all_workflow_states << "(#{quote(role_id)}, #{quote(type_id)}, #{quote(status_a_id)}, #{quote(status_b_id)})" unless status_a_id == status_b_id
            end
          end
        end
      end

      return if all_workflow_states.empty?

      all_workflow_states.in_groups_of(100, false) do |some_workflow_states|
        some_workflow_states = some_workflow_states.join(', ')

        execute <<-SQL
          INSERT INTO #{db_workflows_table}
            (
              role_id,
              type_id,
              old_status_id,
              new_status_id
            )
          VALUES
            #{some_workflow_states}
        SQL
      end
    end
  end

  def enable_types_in_projects
    say_with_time_silently 'Enabling new types in those projects that had the former legacy_planning_element_types enabled' do
      execute <<-SQL
        INSERT INTO #{db_projects_types_table}
          (
            project_id,
            type_id
          )
        SELECT project_id, new_id
        FROM #{db_legacy_enabled_types_table} AS epet
        LEFT JOIN #{db_legacy_types_table} AS pet
        ON epet.planning_element_type_id = pet.id
      SQL
    end
  end

  def remove_types_in_projects
    say_with_time_silently 'Removing enabled types from projects' do
      execute <<-SQL
        DELETE FROM #{db_projects_types_table}
        WHERE
          type_id IN (SELECT new_id
                      FROM #{db_legacy_types_table})
      SQL
    end
  end

  def remove_workflow_for_former_pe_types
    say_with_time_silently 'Removing workflows from pe_types' do
      execute <<-SQL
        DELETE FROM #{db_workflows_table}
        WHERE
          type_id IN (SELECT new_id
                      FROM #{db_legacy_types_table})
      SQL
    end
  end

  def remove_pe_types_from_types
    say_with_time_silently 'Removing all types that are former planning_element_types' do
      execute <<-SQL
        DELETE FROM #{db_types_table}
        WHERE
          id IN (SELECT new_id
                 FROM #{db_legacy_types_table})
      SQL
    end
  end

  def remove_new_id_column
    remove_column :legacy_planning_element_types, :new_id
  end

  def db_types_table
    @db_types_table ||= quote_table_name('types')
  end

  def db_legacy_types_table
    @db_legacy_types_table ||= quote_table_name('legacy_planning_element_types')
  end

  def db_status_table
    @db_status_table ||= quote_table_name('issue_statuses')
  end

  def db_roles_table
    @db_roles_table ||= quote_table_name('roles')
  end

  def db_workflows_table
    @db_workflows_table ||= quote_table_name('workflows')
  end

  def db_legacy_enabled_types_table
    @db_legacy_enabled_types ||= quote_table_name('legacy_enabled_planning_element_types')
  end

  def db_projects_types_table
    @db_projects_types_table ||= quote_table_name('projects_types')
  end
end
