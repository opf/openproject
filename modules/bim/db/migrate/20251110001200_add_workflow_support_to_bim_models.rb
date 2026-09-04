# frozen_string_literal: true

class AddWorkflowSupportToBimModels < ActiveRecord::Migration[7.1]
  def change
    # Add workflow support to BCF Issues
    add_column :bcf_issues, :workflow_state, :string, limit: 50
    add_reference :bcf_issues, :workflow_template,
                  foreign_key: { to_table: :bim_workflow_templates },
                  type: :bigint,
                  index: true
    add_column :bcf_issues, :workflow_state_updated_at, :datetime
    add_index :bcf_issues, :workflow_state

    # Add workflow support to Clashes
    # Note: Clashes already have 'status' field, but we add workflow_state for formal workflows
    add_column :bim_clashes, :workflow_state, :string, limit: 50
    add_reference :bim_clashes, :workflow_template,
                  foreign_key: { to_table: :bim_workflow_templates },
                  type: :bigint,
                  index: true
    add_column :bim_clashes, :workflow_state_updated_at, :datetime
    add_index :bim_clashes, :workflow_state

    # Add workflow support to Element Links
    add_column :bim_element_links, :workflow_state, :string, limit: 50
    add_reference :bim_element_links, :workflow_template,
                  foreign_key: { to_table: :bim_workflow_templates },
                  type: :bigint,
                  index: true
    add_column :bim_element_links, :workflow_state_updated_at, :datetime
    add_index :bim_element_links, :workflow_state
  end
end
