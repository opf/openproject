# frozen_string_literal: true

class ConvertCustomActionsToAutomations < ActiveRecord::Migration[8.1]
  class MigrationAutomation < ApplicationRecord
    self.table_name = "automations"
  end

  class MigrationTrigger < ApplicationRecord
    self.table_name = "automation_triggers"
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

    rename_habtm_table :automations_projects, :custom_actions_projects, :automation_id, :custom_action_id
    rename_habtm_table :automations_types, :custom_actions_types, :automation_id, :custom_action_id
    rename_habtm_table :automations_roles, :custom_actions_roles, :automation_id, :custom_action_id
    rename_habtm_table :automations_statuses, :custom_actions_statuses, :automation_id, :custom_action_id

    rename_table :automations, :custom_actions
  end

  private

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
