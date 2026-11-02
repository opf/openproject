# frozen_string_literal: true

# Automated test result ingest (CI / GitHub Actions):
# - test cases get an automation reference ("tests/login.spec.ts#Login › rejects bad password");
# - runs know their source (manual | automation), CI metadata and an external reference
#   ("github:owner/repo:run_id:attempt") so parallel shards report into one run;
# - every upload is recorded as an automation import (counts, unmatched tests, warnings);
# - results carry source, duration, the reported test id and details (error, retry, flaky, …).
class AddAutomationToTestManagement < ActiveRecord::Migration[8.0]
  def change
    add_column :tm_test_cases, :automation_reference, :string, limit: 1024
    add_index :tm_test_cases, %i[project_id automation_reference],
              unique: true,
              where: "automation_reference IS NOT NULL AND deleted_at IS NULL",
              name: "index_tm_test_cases_on_project_and_automation_ref"

    add_column :tm_test_runs, :source, :string, null: false, default: "manual", limit: 16
    add_column :tm_test_runs, :completion_source, :string, limit: 16
    add_column :tm_test_runs, :external_ref, :string, limit: 255
    add_column :tm_test_runs, :ci_metadata, :jsonb, null: false, default: {}
    add_index :tm_test_runs, %i[project_id external_ref],
              unique: true,
              where: "external_ref IS NOT NULL",
              name: "index_tm_test_runs_on_project_and_external_ref"

    create_table :tm_automation_imports do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :test_run, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :format, null: false, limit: 32
      t.string :state, null: false, default: "queued", limit: 16
      t.string :digest, limit: 64
      t.integer :parsed_count, null: false, default: 0
      t.integer :matched_count, null: false, default: 0
      t.integer :created_cases_count, null: false, default: 0
      t.integer :unmatched_count, null: false, default: 0
      t.integer :attachments_count, null: false, default: 0
      t.jsonb :unmatched, null: false, default: []
      t.jsonb :warnings, null: false, default: []
      t.jsonb :options, null: false, default: {}
      t.text :error
      t.timestamps null: false
    end
    add_index :tm_automation_imports, %i[test_run_id digest],
              unique: true,
              where: "digest IS NOT NULL",
              name: "index_tm_automation_imports_on_run_and_digest"

    add_column :tm_test_results, :source, :string, null: false, default: "manual", limit: 16
    add_column :tm_test_results, :duration_ms, :integer
    add_column :tm_test_results, :external_id, :string, limit: 1024
    add_column :tm_test_results, :details, :jsonb, null: false, default: {}
    add_reference :tm_test_results, :import,
                  foreign_key: { to_table: :tm_automation_imports, on_delete: :nullify },
                  index: true
  end
end
