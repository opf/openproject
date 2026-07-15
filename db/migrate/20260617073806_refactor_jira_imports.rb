# frozen_string_literal: true

class RefactorJiraImports < ActiveRecord::Migration[8.1]
  def change
    remove_column :jira_imports, :status, :string
    remove_column :jira_imports, :cursor, :jsonb
    remove_column :jira_imports, :import_time_point, :timestamp
    add_column :jira_imports, :import_batch_id, :string

    create_table(:jira_import_job_cursors) do |t|
      t.belongs_to :jira_import
      t.string   :job_class, null: false
      t.jsonb    :arguments, null: false
      t.jsonb    :cursor, null: false
    end

    add_index :jira_import_job_cursors,
              %i[jira_import_id job_class arguments],
              unique: true
  end
end
