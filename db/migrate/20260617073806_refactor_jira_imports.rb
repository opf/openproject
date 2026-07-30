# frozen_string_literal: true

class RefactorJiraImports < ActiveRecord::Migration[8.1]
  def change
    change_table :jira_imports, bulk: true do |t|
      t.remove :status, type: :string if t.column_exists?(:status)
      t.remove :cursor, type: :jsonb
      t.remove :import_time_point, type: :timestamp
      t.string :import_batch_id
    end

    create_table(:jira_import_job_cursors) do |t|
      t.belongs_to :jira_import
      t.string   :job_class, null: false
      t.jsonb    :arguments, null: false
      t.jsonb    :cursor, null: false
      t.timestamps
    end

    add_index :jira_import_job_cursors,
              %i[jira_import_id job_class arguments],
              unique: true
  end
end
