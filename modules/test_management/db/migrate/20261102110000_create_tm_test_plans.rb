# frozen_string_literal: true

# Optional test plans (campaigns) that group and spawn test runs, including a
# configuration matrix. All plan FKs on runs are nullable so standalone runs stay first-class.
class CreateTmTestPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_test_plans do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.references :milestone, foreign_key: { to_table: :tm_milestones, on_delete: :nullify }, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.date :start_date
      t.date :end_date
      t.string :state, null: false, default: "active", limit: 16
      t.datetime :finished_at
      t.references :finished_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
    add_index :tm_test_plans, %i[project_id state], name: "index_tm_test_plans_on_project_and_state"

    create_table :tm_test_plan_entries do |t|
      t.references :test_plan, null: false, foreign_key: { to_table: :tm_test_plans, on_delete: :cascade }, index: true
      t.string :name, null: false, limit: 255
      t.text :description
      t.integer :position, null: false, default: 0
      t.string :selection_mode, null: false, default: "specific", limit: 16
      t.jsonb :filter_options, null: false, default: {}
      t.jsonb :case_ids, null: false, default: []
      t.jsonb :configuration_ids, null: false, default: []
      t.references :assigned_to, foreign_key: { to_table: :users, on_delete: :nullify }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_plan_entries, %i[test_plan_id position],
              name: "index_tm_test_plan_entries_on_plan_and_position"

    create_table :tm_test_plan_work_packages do |t|
      t.references :test_plan, null: false, foreign_key: { to_table: :tm_test_plans, on_delete: :cascade }, index: false
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }, index: true
      t.timestamps null: false
    end
    add_index :tm_test_plan_work_packages, %i[test_plan_id work_package_id], unique: true,
                                                                             name: "index_tm_test_plan_wps_on_plan_and_wp"

    add_reference :tm_test_runs, :test_plan,
                  foreign_key: { to_table: :tm_test_plans, on_delete: :nullify }, index: true
    add_reference :tm_test_runs, :test_plan_entry,
                  foreign_key: { to_table: :tm_test_plan_entries, on_delete: :nullify }, index: true
    add_column :tm_test_runs, :configuration_ids, :jsonb, null: false, default: []
    add_column :tm_test_runs, :configuration_label, :string, limit: 255
  end
end
