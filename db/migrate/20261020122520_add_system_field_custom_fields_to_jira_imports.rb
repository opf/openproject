# frozen_string_literal: true

class AddSystemFieldCustomFieldsToJiraImports < ActiveRecord::Migration[8.1]
  def change
    add_column :jira_imports, :system_field_custom_fields, :jsonb, default: {}, null: false
  end
end
