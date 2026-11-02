# frozen_string_literal: true

class CreateTestManagementTables < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_project_settings do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :display_prefix, limit: 32
      t.jsonb :options, null: false, default: {}
      t.timestamps null: false
    end

    create_table :tm_suites do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :parent, foreign_key: { to_table: :tm_suites }, index: true
      t.string :name, null: false, limit: 255
      t.integer :position, null: false, default: 0
      t.timestamps null: false
    end

    add_index :tm_suites, %i[project_id parent_id name],
              unique: true,
              nulls_not_distinct: true,
              name: "index_tm_suites_on_project_parent_name"

    # Global bigint identity (never reused). Soft-delete via deleted_at.
    create_table :tm_test_cases do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :suite, foreign_key: { to_table: :tm_suites }, index: true
      t.string :title, null: false, limit: 255
      t.text :description
      t.text :preconditions
      t.string :priority, null: false, default: "medium", limit: 32
      t.string :status, null: false, default: "ready", limit: 32
      t.boolean :automated, null: false, default: false
      t.references :author, foreign_key: { to_table: :users }, index: true
      t.references :assigned_to, foreign_key: { to_table: :users }, index: true
      t.integer :lock_version, null: false, default: 0
      t.datetime :deleted_at
      t.timestamps null: false
    end

    add_index :tm_test_cases, :deleted_at
    add_index :tm_test_cases, %i[project_id status], where: "deleted_at IS NULL"

    create_table :tm_test_steps do |t|
      t.references :test_case, null: false, foreign_key: { to_table: :tm_test_cases }, index: true
      t.integer :position, null: false, default: 0
      t.text :action
      t.text :expected_result
      t.text :data
      t.timestamps null: false
    end

    add_index :tm_test_steps, %i[test_case_id position]
  end
end
