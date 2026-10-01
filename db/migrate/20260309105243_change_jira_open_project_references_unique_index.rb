# frozen_string_literal: true

class ChangeJiraOpenProjectReferencesUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :jira_open_project_references, %i[op_entity_id op_entity_class], unique: true
    add_index :jira_open_project_references, %i[jira_id op_entity_id op_entity_class], unique: true
  end
end
