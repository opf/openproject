# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/utils")

# CI connections and run iterations:
# - a project can have several CI connections (GitHub / GitLab repositories). The access token
#   is stored encrypted (TestManagement::CiConnections::TokenCipher) and is never rendered back;
# - a test run can be executed several times ("iterations", e.g. the "Smoke" run gets a new
#   iteration for every push). Results and imports remember their iteration so every iteration
#   has its own counts / pass rate, while the run cases always show the current one;
# - automation imports remember the external reference of the upload. The replay protection
#   (same payload digest) is now scoped to the iteration, so the same report may be uploaded as
#   a new iteration of the same run.
class AddCiConnectionsAndIterations < ActiveRecord::Migration[8.0]
  include Migration::Utils

  def change
    create_table :tm_ci_connections do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.string :provider, null: false, limit: 16
      t.string :base_url, limit: 255
      t.string :repository, null: false, limit: 255
      t.text :token_ciphertext
      t.datetime :token_updated_at
      t.string :ingest_mode, null: false, default: "new_run", limit: 16
      t.string :target_run_name, limit: 255
      t.boolean :active, null: false, default: true
      t.string :check_status, limit: 32
      t.text :check_message
      t.datetime :checked_at
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_ci_connections, %i[project_id name], unique: true,
                                                       name: "index_tm_ci_connections_on_project_and_name"
    add_index :tm_ci_connections, %i[project_id provider repository], unique: true,
                                                                      name: "index_tm_ci_connections_on_project_and_repo"

    create_table :tm_test_run_iterations do |t|
      t.references :test_run, null: false, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: true
      t.integer :number, null: false
      t.string :name, limit: 255
      t.string :source, null: false, default: "manual", limit: 16
      t.string :external_ref, limit: 255
      t.jsonb :ci_metadata, null: false, default: {}
      t.references :connection, foreign_key: { to_table: :tm_ci_connections, on_delete: :nullify }, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_run_iterations, %i[test_run_id number], unique: true,
                                                               name: "index_tm_run_iterations_on_run_and_number"
    add_index :tm_test_run_iterations, %i[test_run_id external_ref], unique: true,
                                                                     where: "external_ref IS NOT NULL",
                                                                     name: "index_tm_run_iterations_on_run_and_external_ref"

    add_reference :tm_test_runs, :connection,
                  foreign_key: { to_table: :tm_ci_connections, on_delete: :nullify }, index: true
    add_reference :tm_test_results, :iteration,
                  foreign_key: { to_table: :tm_test_run_iterations, on_delete: :nullify }, index: true
    add_reference :tm_automation_imports, :iteration,
                  foreign_key: { to_table: :tm_test_run_iterations, on_delete: :nullify }, index: true
    add_column :tm_automation_imports, :external_ref, :string, limit: 255

    reversible do |dir|
      dir.up do
        remove_index_on :tm_automation_imports, "index_tm_automation_imports_on_run_and_digest",
                        %w[test_run_id digest]
        add_index :tm_automation_imports, %i[test_run_id iteration_id digest],
                  unique: true, where: "digest IS NOT NULL",
                  name: "index_tm_automation_imports_on_iteration_and_digest"
      end
      dir.down do
        remove_index_on :tm_automation_imports, "index_tm_automation_imports_on_iteration_and_digest",
                        %w[test_run_id iteration_id digest]
        add_index :tm_automation_imports, %i[test_run_id digest],
                  unique: true, where: "digest IS NOT NULL",
                  name: "index_tm_automation_imports_on_run_and_digest"
      end
    end
  end
end
