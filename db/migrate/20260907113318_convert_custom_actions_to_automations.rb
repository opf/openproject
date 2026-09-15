# frozen_string_literal: true

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

require Rails.root.join("db/migrate/migration_utils/utils")

class ConvertCustomActionsToAutomations < ActiveRecord::Migration[8.1]
  include Migration::Utils

  JOIN_TABLES = {
    statuses: :status_id,
    roles: :role_id,
    types: :type_id,
    projects: :project_id
  }.freeze

  class MigrationAutomation < ApplicationRecord
    self.table_name = "automations"
  end

  class MigrationTrigger < ApplicationRecord
    self.table_name = "automation_triggers"
    self.inheritance_column = nil
  end

  def up
    rename_table :custom_actions, :automations

    JOIN_TABLES.each do |suffix, other_column|
      rename_join_table(:"custom_actions_#{suffix}", :"automations_#{suffix}",
                        :custom_action_id, :automation_id, other_column)
    end

    create_table :automation_triggers do |t|
      t.references :automation, null: false, foreign_key: true, index: true
      t.string :type, null: false
      t.jsonb :options, null: false, default: {}
      t.integer :position

      t.timestamps
    end

    MigrationAutomation.reset_column_information
    MigrationTrigger.reset_column_information

    MigrationAutomation.find_each do |automation|
      MigrationTrigger.create!(
        automation_id: automation.id,
        type: "Automations::Triggers::Manual",
        options: { button_label: automation.name },
        position: 1
      )
    end
  end

  def down
    drop_table :automation_triggers

    JOIN_TABLES.reverse_each do |suffix, other_column|
      rename_join_table(:"automations_#{suffix}", :"custom_actions_#{suffix}",
                        :automation_id, :custom_action_id, other_column)
    end

    rename_table :automations, :custom_actions
  end

  private

  # rename_table and rename_column already take care of renaming the Rails-default indexes.
  # So we only have to normalize possibly remaining indexes here
  def rename_join_table(from_table, to_table, old_fk, new_fk, other_column)
    rename_table from_table, to_table
    rename_column to_table, old_fk, new_fk

    normalize_index to_table, "index_#{from_table}_on_#{old_fk}", "index_#{to_table}_on_#{new_fk}", new_fk
    normalize_index to_table, "index_#{from_table}_on_#{other_column}", "index_#{to_table}_on_#{other_column}",
                    other_column
  end

  def normalize_index(table, legacy_name, canonical_name, column)
    actual_name = resolved_index_name(table, legacy_name, [column])

    if actual_name.nil?
      add_index table, column, name: canonical_name
    elsif actual_name != canonical_name
      rename_index table, actual_name, canonical_name
    end
  end
end
