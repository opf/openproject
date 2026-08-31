# frozen_string_literal: true

class RefactorJiraImports < ActiveRecord::Migration[8.1]
  # rubocop:disable Metrics/AbcSize
  def change
    reversible do |dir|
      dir.up do
        connection.execute <<~SQL.squish
          TRUNCATE TABLE
            jira_issues,
            jira_projects,
            jira_statuses,
            jira_priorities,
            jira_fields,
            jira_users,
            jira_issue_types,
            jira_imports,
            jira_import_transitions,
            jira_open_project_references,
            jira_status_categories,
            jira_project_types
          RESTART IDENTITY
        SQL
      end
    end

    change_table :jira_open_project_references, bulk: true do |t|
      t.remove_index %i[jira_id op_entity_id op_entity_class], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.change_null :jira_import_id, false
      t.index %i[jira_import_id op_entity_id op_entity_class], unique: true
    end

    change_table :jira_imports, bulk: true do |t|
      t.remove :status, type: :string
      t.remove :cursor, type: :jsonb
      t.remove :import_time_point, type: :timestamp
      t.remove :error, type: :string
      t.remove :job_id, type: :string
    end

    change_table :jira_projects, bulk: true do |t|
      t.remove_index %i[jira_id jira_project_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_project_id, :origin_id
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_issues, bulk: true do |t|
      t.remove_index %i[jira_id jira_issue_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_issue_id, :origin_id
      t.remove :jira_project_id, type: :string
      # It is fine because we are truncating this table in this migration
      # rubocop:disable Rails/NotNullColumn
      t.references :jira_project, foreign_key: { on_delete: :cascade, on_update: :cascade }, null: false
      # rubocop:enable Rails/NotNullColumn
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_statuses, bulk: true do |t|
      t.remove_index %i[jira_id jira_status_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_status_id, :origin_id
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_priorities, bulk: true do |t|
      t.remove_index %i[jira_id jira_priority_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_priority_id, :origin_id
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_fields, bulk: true do |t|
      t.remove_index %i[jira_id jira_field_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_field_id, :origin_id
      t.jsonb :issue_values
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_users, bulk: true do |t|
      t.remove_index %i[jira_id jira_user_key], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_user_key, :origin_id
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    change_table :jira_issue_types, bulk: true do |t|
      t.remove_index %i[jira_id jira_issue_type_id], unique: true
      t.remove_references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.rename :jira_issue_type_id, :origin_id
      t.index %i[jira_import_id origin_id], unique: true
      t.change_null :origin_id, false
      t.change_null :jira_import_id, false
    end

    create_table :jira_import_job_cursors do |t|
      t.belongs_to :jira_import, null: false, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.string :job_class, null: false
      t.jsonb :arguments, null: false
      t.jsonb :cursor, null: false
      t.timestamps
      t.index %i[jira_import_id job_class arguments], unique: true
    end

    drop_table :jira_status_categories do |t|
      t.jsonb :payload
      t.string :jira_status_category_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_status_category_id], unique: true
      t.timestamps
    end

    drop_table :jira_project_types do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.timestamps
    end
  end
  # rubocop:enable Metrics/AbcSize
end
