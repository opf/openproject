# frozen_string_literal: true

module Bim
  class WorkflowTemplate < ApplicationRecord
    self.table_name = 'bim_workflow_templates'

    # Workflow types define which models this template applies to
    enum workflow_type: {
      issue_review: 0,        # For BCF issue review and approval
      clash_resolution: 1,    # For clash detection and resolution
      element_approval: 2,    # For element link approvals
      custom: 3               # User-defined workflows
    }

    # Associations
    belongs_to :project, optional: true
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :updated_by, class_name: 'User', optional: true
    has_many :workflow_logs, class_name: 'Bim::WorkflowLog', dependent: :restrict_with_error

    # Validations
    validates :name, presence: true, length: { maximum: 100 }
    validates :workflow_type, presence: true
    validates :states, presence: true
    validates :transitions, presence: true
    validate :validate_states_schema
    validate :validate_transitions_schema
    validate :validate_initial_state_exists
    validate :validate_unique_default_per_type

    # Scopes
    scope :active, -> { where(active: true) }
    scope :default_templates, -> { where(is_default: true) }
    scope :for_project, ->(project_id) { where(project_id: project_id).or(where(project_id: nil)) }
    scope :for_type, ->(type) { where(workflow_type: type) }
    scope :global, -> { where(project_id: nil) }

    # Get the initial state (where initial: true)
    def initial_state
      states.find { |s| s['initial'] == true }&.dig('name')
    end

    # Get all final states (where final: true)
    def final_states
      states.select { |s| s['final'] == true }.map { |s| s['name'] }
    end

    # Get state definition by name
    def state_definition(state_name)
      states.find { |s| s['name'] == state_name }
    end

    # Get transition definition by name
    def transition_definition(transition_name)
      transitions.find { |t| t['name'] == transition_name }
    end

    # Get all valid transitions from a given state
    def transitions_from(state_name)
      transitions.select { |t| t['from'] == state_name || t['from'] == '*' }
    end

    # Get all transitions to a given state
    def transitions_to(state_name)
      transitions.select { |t| t['to'] == state_name }
    end

    # Check if a transition is valid from current state
    def transition_allowed?(from_state, transition_name)
      transition = transition_definition(transition_name)
      return false unless transition

      # Check if transition is allowed from this state
      transition['from'] == from_state || transition['from'] == '*'
    end

    # Get available transitions for a state
    def available_transitions(state_name, context = {})
      transitions_from(state_name).select do |transition|
        # Check guards if specified
        next true unless transition['guard']

        # Guards can be evaluated with context
        evaluate_guard(transition['guard'], context)
      end
    end

    # Get state label (display name)
    def state_label(state_name)
      state_definition(state_name)&.dig('label') || state_name.humanize
    end

    # Get state color
    def state_color(state_name)
      state_definition(state_name)&.dig('color') || '#gray'
    end

    # Get transition label
    def transition_label(transition_name)
      transition_definition(transition_name)&.dig('label') || transition_name.humanize
    end

    # Check if state is initial
    def initial_state?(state_name)
      state_definition(state_name)&.dig('initial') == true
    end

    # Check if state is final
    def final_state?(state_name)
      state_definition(state_name)&.dig('final') == true
    end

    # Get all state names
    def state_names
      states.map { |s| s['name'] }
    end

    # Get all transition names
    def transition_names
      transitions.map { |t| t['name'] }
    end

    # Clone template for a specific project
    def clone_for_project(project, user: nil)
      new_template = dup
      new_template.project = project
      new_template.is_default = false
      new_template.name = "#{name} (#{project.name})"
      new_template.created_by = user
      new_template.save!
      new_template
    end

    # Generate state machine diagram (Mermaid syntax)
    def state_machine_diagram
      lines = ["stateDiagram-v2"]

      states.each do |state|
        label = state['label'] || state['name'].humanize
        lines << "  #{state['name']}: #{label}"
      end

      transitions.each do |transition|
        label = transition['label'] || transition['name'].humanize
        from = transition['from'] == '*' ? '[*]' : transition['from']
        to = transition['to']
        lines << "  #{from} --> #{to}: #{label}"
      end

      lines.join("\n")
    end

    # Export template as YAML
    def export_yaml
      {
        'name' => name,
        'description' => description,
        'workflow_type' => workflow_type,
        'states' => states,
        'transitions' => transitions,
        'configuration' => configuration
      }.to_yaml
    end

    # Import template from YAML
    def self.import_yaml(yaml_content, user: nil, project: nil)
      data = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
      create!(
        name: data['name'],
        description: data['description'],
        workflow_type: data['workflow_type'],
        states: data['states'],
        transitions: data['transitions'],
        configuration: data['configuration'] || {},
        created_by: user,
        project: project
      )
    end

    private

    def evaluate_guard(guard_expression, context)
      # For now, always return true
      # In a full implementation, this would evaluate the guard expression
      # with the provided context (e.g., user permissions, object state)
      true
    end

    def validate_states_schema
      return if states.blank?

      unless states.is_a?(Array)
        errors.add(:states, 'must be an array')
        return
      end

      states.each_with_index do |state, index|
        unless state.is_a?(Hash) && state['name'].present?
          errors.add(:states, "state at index #{index} must have a 'name' field")
        end
      end

      # Check for duplicate state names
      state_names = states.map { |s| s['name'] }
      if state_names.uniq.length != state_names.length
        errors.add(:states, 'contains duplicate state names')
      end
    end

    def validate_transitions_schema
      return if transitions.blank?

      unless transitions.is_a?(Array)
        errors.add(:transitions, 'must be an array')
        return
      end

      transitions.each_with_index do |transition, index|
        unless transition.is_a?(Hash)
          errors.add(:transitions, "transition at index #{index} must be a hash")
          next
        end

        unless transition['name'].present?
          errors.add(:transitions, "transition at index #{index} must have a 'name' field")
        end

        unless transition['from'].present?
          errors.add(:transitions, "transition at index #{index} must have a 'from' field")
        end

        unless transition['to'].present?
          errors.add(:transitions, "transition at index #{index} must have a 'to' field")
        end

        # Validate from/to states exist (except wildcard '*')
        if transition['from'] != '*' && transition['from'].present?
          unless state_names.include?(transition['from'])
            errors.add(:transitions, "transition '#{transition['name']}' references unknown state '#{transition['from']}'")
          end
        end

        if transition['to'].present?
          unless state_names.include?(transition['to'])
            errors.add(:transitions, "transition '#{transition['name']}' references unknown state '#{transition['to']}'")
          end
        end
      end

      # Check for duplicate transition names
      transition_names_list = transitions.map { |t| t['name'] }
      if transition_names_list.uniq.length != transition_names_list.length
        errors.add(:transitions, 'contains duplicate transition names')
      end
    end

    def validate_initial_state_exists
      return if states.blank?

      initial_states = states.select { |s| s['initial'] == true }

      if initial_states.empty?
        errors.add(:states, 'must have at least one initial state (initial: true)')
      elsif initial_states.size > 1
        errors.add(:states, 'can only have one initial state')
      end
    end

    def validate_unique_default_per_type
      return unless is_default? && workflow_type.present?

      existing = self.class.where(
        workflow_type: workflow_type,
        is_default: true,
        project_id: project_id
      ).where.not(id: id)

      if existing.exists?
        errors.add(:base, "A default #{workflow_type} workflow already exists for this scope")
      end
    end
  end
end
