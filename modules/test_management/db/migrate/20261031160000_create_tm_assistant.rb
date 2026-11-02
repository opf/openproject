# frozen_string_literal: true

# Test Assistant (0014): generation requests (drafts of test cases produced by the configured
# AI provider) and the per-user, per-project chat history including proposed actions.
class CreateTmAssistant < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_assistant_generations do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      # queued | running | done | failed
      t.string :status, null: false, default: "queued", limit: 16
      # work_package | text | pull_request | code
      t.string :source_type, null: false, limit: 16
      t.jsonb :source, null: false, default: {}
      t.jsonb :options, null: false, default: {}
      t.jsonb :drafts, null: false, default: []
      t.jsonb :saved_case_ids, null: false, default: []
      t.text :error
      t.string :provider_model, limit: 255
      t.timestamps
    end
    add_index :tm_assistant_generations, %i[project_id user_id created_at], name: "index_tm_assistant_generations_on_owner"

    create_table :tm_assistant_messages do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      # user | assistant
      t.string :role, null: false, limit: 16
      t.text :content
      # pending | done | failed (assistant messages are pending while the job runs)
      t.string :state, null: false, default: "done", limit: 16
      # A proposed write ({ "name" => "create_test_run", "params" => {...}, "preview" => [...] })
      t.jsonb :action
      # proposed | confirmed | cancelled | failed
      t.string :action_status, limit: 16
      t.jsonb :action_result
      t.string :provider_model, limit: 255
      t.timestamps
    end
    add_index :tm_assistant_messages, %i[project_id user_id id], name: "index_tm_assistant_messages_on_owner"
  end
end
