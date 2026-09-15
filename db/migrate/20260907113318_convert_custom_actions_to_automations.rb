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

  ACTION_KEY_TO_STI = {
    "assigned_to" => "Automations::Actions::AssignedTo",
    "responsible" => "Automations::Actions::Responsible",
    "status" => "Automations::Actions::Status",
    "priority" => "Automations::Actions::Priority",
    "type" => "Automations::Actions::Type",
    "project" => "Automations::Actions::Project",
    "notify" => "Automations::Actions::Notify",
    "done_ratio" => "Automations::Actions::DoneRatio",
    "estimated_hours" => "Automations::Actions::EstimatedHours",
    "start_date" => "Automations::Actions::StartDate",
    "due_date" => "Automations::Actions::DueDate",
    "date" => "Automations::Actions::Date"
  }.freeze

  CUSTOM_FIELD_FORMAT_TO_STI = {
    "string" => "Automations::Actions::CustomField::ForString",
    "text" => "Automations::Actions::CustomField::ForText",
    "link" => "Automations::Actions::CustomField::ForLink",
    "int" => "Automations::Actions::CustomField::ForInteger",
    "float" => "Automations::Actions::CustomField::ForFloat",
    "date" => "Automations::Actions::CustomField::ForDate",
    "bool" => "Automations::Actions::CustomField::ForBoolean",
    "user" => "Automations::Actions::CustomField::ForUser",
    "list" => "Automations::Actions::CustomField::ForAssociated",
    "version" => "Automations::Actions::CustomField::ForAssociated"
  }.freeze

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

  class MigrationAction < ApplicationRecord
    self.table_name = "automation_actions"
    self.inheritance_column = nil
  end

  class MigrationCustomField < ApplicationRecord
    self.table_name = "custom_fields"
    self.inheritance_column = nil
  end

  def up
    rename_table :custom_actions, :automations

    JOIN_TABLES.each do |suffix, other_column|
      rename_join_table(:"custom_actions_#{suffix}", :"automations_#{suffix}",
                        :custom_action_id, :automation_id, other_column)
    end

    create_trigger_table
    create_action_table
    backfill_triggers_and_actions

    remove_column :automations, :actions
  end

  def down
    restore_serialized_actions

    drop_table :automation_actions
    drop_table :automation_triggers

    JOIN_TABLES.reverse_each do |suffix, other_column|
      rename_join_table(:"automations_#{suffix}", :"custom_actions_#{suffix}",
                        :automation_id, :custom_action_id, other_column)
    end

    rename_table :automations, :custom_actions
  end

  private

  def create_trigger_table
    create_table :automation_triggers do |t|
      t.references :automation, null: false, foreign_key: true, index: true
      t.string :type, null: false
      t.jsonb :options, null: false, default: {}
      t.integer :position

      t.timestamps
    end
  end

  def create_action_table
    create_table :automation_actions do |t|
      t.references :automation, null: false, foreign_key: true, index: true
      t.string :type, null: false
      t.jsonb :options, null: false, default: {}
      t.integer :position

      t.timestamps
    end
  end

  def backfill_triggers_and_actions
    MigrationAutomation.reset_column_information
    MigrationTrigger.reset_column_information
    MigrationAction.reset_column_information

    MigrationAutomation.find_each do |automation|
      MigrationTrigger.create!(
        automation_id: automation.id,
        type: "Automations::Triggers::Manual",
        options: { button_label: automation.name },
        position: 1
      )

      backfill_actions(automation)
    end
  end

  def restore_serialized_actions
    add_column :automations, :actions, :text

    MigrationAutomation.reset_column_information

    MigrationAutomation.find_each do |automation|
      entries = MigrationAction
        .where(automation_id: automation.id)
        .order(:position, :id)
        .pluck(:type, :options)
        .filter_map { |type, options| serialize_action(type, options) }

      automation.update_column(:actions, YAML.dump(entries))
    end
  end

  def backfill_actions(automation)
    raw = automation[:actions]
    return if raw.blank?

    parsed = YAML.safe_load(raw, permitted_classes: [Symbol, Date, ActiveSupport::HashWithIndifferentAccess])
    return unless parsed.is_a?(Array)

    parsed.each_with_index do |entry, index|
      key, values = entry
      type, options = resolve_action(key, values)
      next unless type

      MigrationAction.create!(
        automation_id: automation.id,
        type:,
        options:,
        position: index + 1
      )
    end
  end

  def resolve_action(key, values)
    key_str = key.to_s
    if (sti = ACTION_KEY_TO_STI[key_str])
      [sti, { values: Array(values) }]
    elsif (match = key_str.match(/\Acustom_field_(\d+)\z/))
      resolve_custom_field_action(match[1].to_i, values)
    end
  end

  def resolve_custom_field_action(custom_field_id, values)
    cf = MigrationCustomField.find_by(id: custom_field_id)
    return unless cf

    sti = CUSTOM_FIELD_FORMAT_TO_STI[cf.field_format]
    return unless sti

    [sti, { custom_field_id:, values: Array(values) }]
  end

  def serialize_action(type, options)
    options = options.is_a?(Hash) ? options.with_indifferent_access : {}
    values = Array(options["values"]).map(&:to_s)

    if (key = ACTION_KEY_TO_STI.invert[type])
      [key, values]
    elsif type.start_with?("Automations::Actions::CustomField::")
      cf_id = options["custom_field_id"]
      ["custom_field_#{cf_id}", values] if cf_id
    end
  end

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
