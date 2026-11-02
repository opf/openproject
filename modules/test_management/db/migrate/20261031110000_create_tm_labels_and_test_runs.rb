# frozen_string_literal: true

# Labels for test cases, test runs, run cases and per-case results.
#
# IDs: like tm_test_cases (0001), every table uses the default bigint identity
# primary key, i.e. one global PostgreSQL sequence per table. IDs are numeric,
# unique across all projects and never reused (sequences are not reset or
# rewound; deleted rows leave gaps).
class CreateTmLabelsAndTestRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_labels do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 64
      t.string :color, null: false, limit: 32
      t.timestamps null: false
    end
    add_index :tm_labels, %i[project_id name], unique: true

    create_table :tm_test_case_labels do |t|
      t.references :test_case, null: false, foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }, index: true
      t.references :label, null: false, foreign_key: { to_table: :tm_labels, on_delete: :cascade }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_case_labels, %i[test_case_id label_id], unique: true

    create_table :tm_test_runs do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      # new | in_progress | completed | cancelled
      t.string :state, null: false, default: "new", limit: 32
      # all | specific | dynamic
      t.string :selection_mode, null: false, default: "specific", limit: 16
      # dynamic mode: { "label_ids" => [..], "automation" => "any|automated|manual", "suite_ids" => [..] }
      t.jsonb :filter_options, null: false, default: {}
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.date :start_date
      t.date :end_date
      t.datetime :finished_at
      t.references :finished_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_index :tm_test_runs, %i[project_id state]

    create_table :tm_test_run_work_packages do |t|
      t.references :test_run, null: false, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: true
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_run_work_packages, %i[test_run_id work_package_id], unique: true,
                                                                           name: "index_tm_test_run_wps_on_run_and_wp"

    create_table :tm_test_run_cases do |t|
      t.references :test_run, null: false, foreign_key: { to_table: :tm_test_runs, on_delete: :cascade }, index: true
      t.references :test_case, null: false, foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      # untested | in_progress | passed | failed | retest | blocked
      t.string :status, null: false, default: "untested", limit: 32
      # Frozen copy of `status` written when the run is completed or cancelled.
      t.string :final_status, limit: 32
      t.timestamps null: false
    end
    add_index :tm_test_run_cases, %i[test_run_id test_case_id], unique: true

    create_table :tm_test_results do |t|
      t.references :run_case, null: false, foreign_key: { to_table: :tm_test_run_cases, on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.string :status, null: false, limit: 32
      t.text :comment
      t.datetime :created_at, null: false
    end
    add_index :tm_test_results, %i[run_case_id created_at]
  end
end
