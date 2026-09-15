# frozen_string_literal: true

class CreateBimWorkflowLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :bim_workflow_logs do |t|
      # Which workflow template was used
      t.references :workflow_template,
                   null: false,
                   foreign_key: { to_table: :bim_workflow_templates },
                   type: :bigint,
                   index: true

      # Polymorphic association to workflowable (Issue, Clash, ElementLink, etc.)
      t.references :workflowable,
                   null: false,
                   polymorphic: true,
                   type: :bigint,
                   index: { name: 'index_workflow_logs_on_workflowable' }

      # Transition details
      t.string :from_state, limit: 50
      t.string :to_state, null: false, limit: 50
      t.string :transition_name, limit: 100

      # Who performed the transition
      t.references :user, null: false, foreign_key: true, type: :bigint

      # Optional comment/note for the transition
      t.text :comment

      # Additional metadata (form fields, validation results, etc.)
      t.jsonb :metadata, default: {}

      # Duration in the previous state (in seconds)
      t.integer :duration_in_state

      # IP address and user agent for audit purposes
      t.string :ip_address, limit: 45
      t.string :user_agent, limit: 255

      # Automated vs manual transition
      t.boolean :automated, default: false, null: false

      # Timestamp
      t.datetime :created_at, null: false
    end

    # Indexes for efficient queries
    add_index :bim_workflow_logs, :from_state
    add_index :bim_workflow_logs, :to_state
    add_index :bim_workflow_logs, :transition_name
    add_index :bim_workflow_logs, :created_at
    add_index :bim_workflow_logs, [:workflowable_type, :workflowable_id, :created_at],
              name: 'index_workflow_logs_on_workflowable_and_date'
    add_index :bim_workflow_logs, :metadata, using: :gin
  end
end
