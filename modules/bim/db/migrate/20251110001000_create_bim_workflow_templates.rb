# frozen_string_literal: true

class CreateBimWorkflowTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :bim_workflow_templates do |t|
      t.string :name, null: false, limit: 100
      t.text :description

      # Workflow type determines which models this template applies to
      # issue_review: For BCF issues
      # clash_resolution: For clash detection and approval
      # element_approval: For element link approvals
      # custom: User-defined workflows
      t.integer :workflow_type, null: false, default: 0

      # JSON schema defining workflow states
      # Example: [
      #   { name: "draft", label: "Draft", color: "#gray", initial: true },
      #   { name: "in_review", label: "In Review", color: "#blue" },
      #   { name: "approved", label: "Approved", color: "#green", final: true }
      # ]
      t.jsonb :states, null: false, default: []

      # JSON schema defining allowed transitions
      # Example: [
      #   {
      #     name: "submit_for_review",
      #     from: "draft",
      #     to: "in_review",
      #     label: "Submit for Review",
      #     guard: "can_submit?",
      #     actions: ["notify_reviewers"],
      #     required_role: "member"
      #   }
      # ]
      t.jsonb :transitions, null: false, default: []

      # Optional project association (null = global template)
      t.references :project, foreign_key: true, type: :bigint, index: true

      # Default template for its type
      t.boolean :is_default, default: false, null: false

      # Active status (allow disabling without deletion)
      t.boolean :active, default: true, null: false

      # Configuration options (notifications, auto-assignments, etc.)
      t.jsonb :configuration, default: {}

      # Audit fields
      t.references :created_by, foreign_key: { to_table: :users }, type: :bigint
      t.references :updated_by, foreign_key: { to_table: :users }, type: :bigint

      t.timestamps
    end

    # Indexes for efficient queries
    add_index :bim_workflow_templates, [:workflow_type, :is_default],
              name: 'index_bim_workflow_templates_on_type_and_default'
    add_index :bim_workflow_templates, [:project_id, :workflow_type],
              name: 'index_bim_workflow_templates_on_project_and_type'
    add_index :bim_workflow_templates, :active
    add_index :bim_workflow_templates, :states, using: :gin
    add_index :bim_workflow_templates, :transitions, using: :gin
  end
end
