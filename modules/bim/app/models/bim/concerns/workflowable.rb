# frozen_string_literal: true

module Bim
  module Concerns
    module Workflowable
      extend ActiveSupport::Concern

      included do
        # Associations
        belongs_to :workflow_template, class_name: 'Bim::WorkflowTemplate', optional: true
        has_many :workflow_logs,
                 as: :workflowable,
                 class_name: 'Bim::WorkflowLog',
                 dependent: :destroy

        # Validations
        validates :workflow_state, inclusion: { in: :valid_workflow_states }, if: :workflow_template
        validate :workflow_state_exists_in_template, if: :workflow_template

        # Callbacks
        before_validation :initialize_workflow_state, if: :new_record?, unless: :workflow_state
        after_save :log_workflow_state_change, if: :saved_change_to_workflow_state?
      end

      # Class methods
      class_methods do
        # Get all records in a specific workflow state
        def in_workflow_state(state)
          where(workflow_state: state)
        end

        # Get all records with workflow enabled
        def with_workflow
          where.not(workflow_template_id: nil)
        end

        # Get all records without workflow
        def without_workflow
          where(workflow_template_id: nil)
        end
      end

      # Instance methods

      # Execute a workflow transition
      def transition_to!(state_or_transition, user:, comment: nil, metadata: {}, request: nil)
        engine = Bim::Services::WorkflowEngine.new(self)

        # Determine if input is a state or transition name
        if workflow_template.state_names.include?(state_or_transition.to_s)
          # Direct state transition
          engine.transition_to_state!(state_or_transition.to_s, user: user, comment: comment, metadata: metadata, request: request)
        else
          # Named transition
          engine.execute_transition!(state_or_transition.to_s, user: user, comment: comment, metadata: metadata, request: request)
        end
      end

      # Get available transitions from current state
      def available_transitions(user: nil)
        return [] unless workflow_template

        engine = Bim::Services::WorkflowEngine.new(self)
        engine.available_transitions(user: user)
      end

      # Check if a transition is allowed
      def can_transition?(transition_name, user: nil)
        return false unless workflow_template

        engine = Bim::Services::WorkflowEngine.new(self)
        engine.can_execute?(transition_name, user: user)
      end

      # Get workflow timeline
      def workflow_timeline
        Bim::WorkflowLog.timeline_for(self)
      end

      # Get workflow statistics
      def workflow_statistics
        Bim::WorkflowLog.statistics_for(self)
      end

      # Check if workflow is in initial state
      def in_initial_state?
        workflow_template&.initial_state?(workflow_state)
      end

      # Check if workflow is in final state
      def in_final_state?
        workflow_template&.final_state?(workflow_state)
      end

      # Get current state definition
      def current_state_definition
        workflow_template&.state_definition(workflow_state)
      end

      # Get current state label
      def workflow_state_label
        workflow_template&.state_label(workflow_state) || workflow_state&.humanize
      end

      # Get current state color
      def workflow_state_color
        workflow_template&.state_color(workflow_state) || '#gray'
      end

      # Reset workflow to initial state
      def reset_workflow!(user:, comment: nil)
        return false unless workflow_template

        initial = workflow_template.initial_state
        transition_to!(initial, user: user, comment: comment || 'Workflow reset')
      end

      # Initialize workflow with a template
      def initialize_workflow!(template, user:)
        self.workflow_template = template
        self.workflow_state = template.initial_state
        self.workflow_state_updated_at = Time.current

        if save
          # Log initial state entry
          Bim::WorkflowLog.create_transition!(
            workflowable: self,
            from_state: nil,
            to_state: workflow_state,
            transition_name: 'initialize',
            user: user,
            comment: 'Workflow initialized',
            automated: false
          )
          true
        else
          false
        end
      end

      # Remove workflow from this object
      def remove_workflow!(user:, comment: nil)
        if workflow_template
          # Log workflow removal
          Bim::WorkflowLog.create_transition!(
            workflowable: self,
            from_state: workflow_state,
            to_state: nil,
            transition_name: 'remove_workflow',
            user: user,
            comment: comment || 'Workflow removed',
            automated: false
          )
        end

        self.workflow_template = nil
        self.workflow_state = nil
        self.workflow_state_updated_at = nil
        save
      end

      # Check if workflow is enabled
      def workflow_enabled?
        workflow_template.present?
      end

      # Get time spent in current state
      def time_in_current_state
        return nil unless workflow_state_updated_at

        Time.current - workflow_state_updated_at
      end

      # Get time in current state (human readable)
      def time_in_current_state_label
        seconds = time_in_current_state&.to_i
        return nil unless seconds

        if seconds < 60
          "#{seconds}s"
        elsif seconds < 3600
          "#{(seconds / 60).round}min"
        elsif seconds < 86400
          "#{(seconds / 3600.0).round(1)}h"
        else
          "#{(seconds / 86400.0).round(1)}d"
        end
      end

      private

      def initialize_workflow_state
        return unless workflow_template

        self.workflow_state = workflow_template.initial_state
        self.workflow_state_updated_at = Time.current
      end

      def log_workflow_state_change
        # This is handled by the WorkflowEngine service
        # We update the timestamp here
        update_column(:workflow_state_updated_at, Time.current)
      end

      def valid_workflow_states
        return [] unless workflow_template

        workflow_template.state_names + [nil]
      end

      def workflow_state_exists_in_template
        return if workflow_state.blank?
        return unless workflow_template

        unless workflow_template.state_names.include?(workflow_state)
          errors.add(:workflow_state, "is not a valid state in the workflow template")
        end
      end
    end
  end
end
