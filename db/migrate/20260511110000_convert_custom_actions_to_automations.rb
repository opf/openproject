# frozen_string_literal: true

class ConvertCustomActionsToAutomations < ActiveRecord::Migration[8.1]
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

    rename_habtm_table :custom_actions_statuses, :automations_statuses, :custom_action_id, :automation_id
    rename_habtm_table :custom_actions_roles, :automations_roles, :custom_action_id, :automation_id
    rename_habtm_table :custom_actions_types, :automations_types, :custom_action_id, :automation_id
    rename_habtm_table :custom_actions_projects, :automations_projects, :custom_action_id, :automation_id

    create_table :automation_triggers do |t|
      t.references :automation, null: false, foreign_key: true, index: true
      t.string :type, null: false
      t.jsonb :options, null: false, default: {}
      t.integer :position

      t.timestamps
    end

    create_table :automation_actions do |t|
      t.references :automation, null: false, foreign_key: true, index: true
      t.string :type, null: false
      t.jsonb :options, null: false, default: {}
      t.integer :position

      t.timestamps
    end

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

    remove_column :automations, :actions
  end

  def down
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

    drop_table :automation_actions
    drop_table :automation_triggers

    rename_habtm_table :automations_projects, :custom_actions_projects, :automation_id, :custom_action_id
    rename_habtm_table :automations_types, :custom_actions_types, :automation_id, :custom_action_id
    rename_habtm_table :automations_roles, :custom_actions_roles, :automation_id, :custom_action_id
    rename_habtm_table :automations_statuses, :custom_actions_statuses, :automation_id, :custom_action_id

    rename_table :automations, :custom_actions
  end

  private

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
        type: type,
        options: options,
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

    [sti, { custom_field_id: custom_field_id, values: Array(values) }]
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

  def rename_habtm_table(from, to, old_fk, new_fk)
    rename_table from, to
    rename_column to, old_fk, new_fk
    rename_fk_index(to, from, to, old_fk, new_fk)
  end

  def rename_fk_index(table, from_name, to_name, old_fk, new_fk)
    old_index_name = "index_#{from_name}_on_#{old_fk}"
    new_index_name = "index_#{to_name}_on_#{new_fk}"

    if index_name_exists?(table, old_index_name)
      rename_index table, old_index_name, new_index_name
    elsif !index_name_exists?(table, new_index_name)
      add_index table, new_fk, name: new_index_name
    end
  end
end
