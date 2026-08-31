# frozen_string_literal: true

class CreateJiraMigrationTables < ActiveRecord::Migration[8.0]
  # rubocop:disable Metrics/AbcSize
  def change
    create_table :jiras do |t|
      t.string :url
      t.string :name
      t.string :personal_access_token

      t.timestamps
    end

    create_table :jira_imports do |t|
      t.string :status
      t.timestamp :import_time_point
      t.jsonb :cursor
      t.bigint :author_id, null: false
      t.jsonb :projects, default: []
      t.jsonb :selected, default: {}
      t.string :error
      t.string :job_id
      t.jsonb :available, default: {}
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
    end

    create_table :jira_projects do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_project_id], unique: true

      t.timestamps
    end

    create_table :jira_project_types do |t|
      t.jsonb :payload
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }

      t.timestamps
    end

    create_table :jira_issues do |t|
      t.jsonb :payload
      t.string :jira_project_id
      t.string :jira_issue_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_issue_id], unique: true

      t.timestamps
    end

    create_table :jira_issue_types do |t|
      t.jsonb :payload
      t.string :jira_issue_type_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_issue_type_id], unique: true

      t.timestamps
    end

    create_table :jira_priorities do |t|
      t.jsonb :payload
      t.string :jira_priority_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_priority_id], unique: true

      t.timestamps
    end

    create_table :jira_statuses do |t|
      t.jsonb :payload
      t.string :jira_status_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_status_id], unique: true

      t.timestamps
    end

    create_table :jira_status_categories do |t|
      t.jsonb :payload
      t.string :jira_status_category_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_status_category_id], unique: true

      t.timestamps
    end

    create_table :jira_fields do |t|
      t.jsonb :payload
      t.string :jira_field_id
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_field_id], unique: true

      t.timestamps
    end

    create_table :jira_users do |t|
      t.jsonb :payload
      t.string :jira_user_key
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[jira_id jira_user_key], unique: true

      t.timestamps
    end

    create_table :jira_open_project_references do |t|
      t.string :op_entity_id
      t.string :op_entity_class
      t.string :jira_entity_id
      t.string :jira_entity_class
      t.boolean :uses_existing, default: false, null: false
      t.references :jira, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :jira_import, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.index %i[op_entity_id op_entity_class], unique: true

      t.timestamps
    end

    create_table :jira_import_transitions do |t|
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.jsonb :metadata, default: {}
      t.integer :sort_key, null: false
      t.integer :jira_import_id, null: false
      t.boolean :most_recent, default: false, null: false

      # If you decide not to include an updated timestamp column in your transition
      # table, you'll need to configure the `updated_timestamp_column` setting in your
      # migration class.
      t.timestamps null: false
    end

    # Foreign keys are optional, but highly recommended
    add_foreign_key :jira_import_transitions, :jira_imports

    add_index(:jira_import_transitions,
              %i(jira_import_id sort_key),
              unique: true,
              name: "index_jira_import_transitions_parent_sort")
    add_index(:jira_import_transitions,
              %i(jira_import_id most_recent),
              unique: true,
              where: "most_recent",
              name: "index_jira_import_transitions_parent_most_recent")
  end
  # rubocop:enable Metrics/AbcSize
end
