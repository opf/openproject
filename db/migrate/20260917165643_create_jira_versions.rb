# frozen_string_literal: true

class CreateJiraVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :jira_versions do |t|
      t.jsonb :payload
      t.string :origin_id, null: false
      t.references :jira_import, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_project, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_import_id origin_id], unique: true

      t.timestamps
    end
  end
end
