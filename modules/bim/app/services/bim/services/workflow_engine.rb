# frozen_string_literal: true

module Bim
  module Services
    class WorkflowEngine
      attr_reader :workflowable, :template, :errors

      def initialize(workflowable)
        @workflowable = workflowable
        @template = workflowable.workflow_template
        @errors = []
      end

      # Execute a named transition
      def execute_transition!(transition_name, user:, comment: nil, metadata: {}, request: nil)
        raise ArgumentError, 'No workflow template configured' unless template

        transition = template.transition_definition(transition_name)
        raise ArgumentError, "Transition '#{transition_name}' not found" unless transition

        current_state = workflowable.workflow_state
        target_state = transition['to']

        # Validate transition is allowed from current state
        unless transition_allowed?(transition, current_state)
          raise InvalidTransitionError, "Transition '#{transition_name}' is not allowed from state '#{current_state}'"
        end

        # Execute guards if specified
        if transition['guard']
          unless evaluate_guard(transition['guard'], user: user)
            raise GuardFailedError, "Guard '#{transition['guard']}' failed for transition '#{transition_name}'"
          end
        end

        # Check required role if specified
        if transition['required_role']
          unless check_role(user, transition['required_role'])
            raise PermissionError, "User does not have required role '#{transition['required_role']}'"
          end
        end

        # Execute the transition
        perform_transition(
          from_state: current_state,
          to_state: target_state,
          transition_name: transition_name,
          user: user,
          comment: comment,
          metadata: metadata,
          request: request,
          automated: false
        )

        # Execute actions if specified
        execute_actions(transition['actions'], user: user, metadata: metadata) if transition['actions']

        # Emit domain event
        emit_workflow_event(transition_name, user: user, metadata: metadata)

        true
      end

      # Direct state transition (bypasses transition validation)
      def transition_to_state!(state_name, user:, comment: nil, metadata: {}, request: nil)
        raise ArgumentError, 'No workflow template configured' unless template
        raise ArgumentError, "State '#{state_name}' not found" unless template.state_names.include?(state_name)

        current_state = workflowable.workflow_state

        perform_transition(
          from_state: current_state,
          to_state: state_name,
          transition_name: 'direct_transition',
          user: user,
          comment: comment,
          metadata: metadata,
          request: request,
          automated: false
        )

        emit_workflow_event('direct_transition', user: user, metadata: metadata)

        true
      end

      # Get available transitions from current state
      def available_transitions(user: nil)
        return [] unless template

        current_state = workflowable.workflow_state
        return [] unless current_state

        template.transitions_from(current_state).select do |transition|
          # Check guards
          next false if transition['guard'] && !evaluate_guard(transition['guard'], user: user)

          # Check required role
          next false if transition['required_role'] && user && !check_role(user, transition['required_role'])

          true
        end
      end

      # Check if a transition can be executed
      def can_execute?(transition_name, user: nil)
        return false unless template

        transition = template.transition_definition(transition_name)
        return false unless transition

        current_state = workflowable.workflow_state
        return false unless transition_allowed?(transition, current_state)

        # Check guards
        return false if transition['guard'] && !evaluate_guard(transition['guard'], user: user)

        # Check required role
        return false if transition['required_role'] && user && !check_role(user, transition['required_role'])

        true
      end

      # Validate workflow state consistency
      def valid?
        @errors = []

        unless template
          @errors << 'No workflow template configured'
          return false
        end

        current_state = workflowable.workflow_state

        unless current_state
          @errors << 'Workflow state is not set'
          return false
        end

        unless template.state_names.include?(current_state)
          @errors << "Current state '#{current_state}' is not valid in template"
          return false
        end

        @errors.empty?
      end

      private

      def perform_transition(from_state:, to_state:, transition_name:, user:, comment:, metadata:, request:, automated:)
        # Update workflow state
        workflowable.workflow_state = to_state
        workflowable.workflow_state_updated_at = Time.current

        # Save the workflowable
        raise ActiveRecord::RecordInvalid, workflowable unless workflowable.save

        # Log the transition
        Bim::WorkflowLog.create_transition!(
          workflowable: workflowable,
          from_state: from_state,
          to_state: to_state,
          transition_name: transition_name,
          user: user,
          comment: comment,
          metadata: metadata,
          automated: automated,
          request: request
        )
      end

      def transition_allowed?(transition, current_state)
        # Wildcard transitions are allowed from any state
        return true if transition['from'] == '*'

        # Check if transition is allowed from current state
        transition['from'] == current_state
      end

      def evaluate_guard(guard_expression, user:)
        # Guard evaluation logic
        # Guards can check various conditions like user permissions, object state, etc.

        case guard_expression
        when 'can_submit?'
          # Check if user can submit (e.g., is member of project)
          workflowable.respond_to?(:project) && user.member_of?(workflowable.project)
        when 'can_approve?'
          # Check if user has approval permissions (e.g., project admin or manager)
          workflowable.respond_to?(:project) && user.admin? || user.allowed_to?(:manage_project, workflowable.project)
        when 'can_reject?'
          # Similar to approve
          workflowable.respond_to?(:project) && user.admin? || user.allowed_to?(:manage_project, workflowable.project)
        when 'always'
          true
        when 'never'
          false
        else
          # Unknown guard - log warning and allow
          Rails.logger.warn "Unknown workflow guard: #{guard_expression}"
          true
        end
      rescue => e
        Rails.logger.error "Error evaluating workflow guard '#{guard_expression}': #{e.message}"
        false
      end

      def check_role(user, role_name)
        # Role checking logic
        case role_name
        when 'admin'
          user.admin?
        when 'manager'
          workflowable.respond_to?(:project) && user.allowed_to?(:manage_project, workflowable.project)
        when 'member'
          workflowable.respond_to?(:project) && user.member_of?(workflowable.project)
        else
          # Unknown role - log warning and deny
          Rails.logger.warn "Unknown workflow role: #{role_name}"
          false
        end
      rescue => e
        Rails.logger.error "Error checking workflow role '#{role_name}': #{e.message}"
        false
      end

      def execute_actions(actions, user:, metadata:)
        Array(actions).each do |action|
          case action
          when 'notify_reviewers'
            notify_reviewers(user: user, metadata: metadata)
          when 'notify_assignee'
            notify_assignee(user: user, metadata: metadata)
          when 'notify_creator'
            notify_creator(user: user, metadata: metadata)
          when 'auto_assign'
            auto_assign(user: user, metadata: metadata)
          when 'create_notification'
            create_notification(user: user, metadata: metadata)
          else
            Rails.logger.warn "Unknown workflow action: #{action}"
          end
        end
      rescue => e
        # Log error but don't fail the transition
        Rails.logger.error "Error executing workflow action: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end

      def emit_workflow_event(transition_name, user:, metadata:)
        # Emit domain event for workflow transition
        OpenProject::Notifications.send(
          'bim_workflow_transitioned',
          workflowable: workflowable,
          transition: transition_name,
          from_state: workflowable.workflow_state_was,
          to_state: workflowable.workflow_state,
          user: user,
          metadata: metadata,
          timestamp: Time.current
        )
      rescue => e
        Rails.logger.error "Error emitting workflow event: #{e.message}"
      end

      # Action implementations

      def notify_reviewers(user:, metadata:)
        # Get reviewers from project members with review permissions
        return unless workflowable.respond_to?(:project)

        project = workflowable.project
        reviewers = project.users.select { |u| u.allowed_to?(:review_bim_models, project) }

        reviewers.each do |reviewer|
          next if reviewer.id == user.id # Don't notify the actor

          Bim::Collaboration::NotificationService.notify_workflow_transition(
            user: reviewer,
            workflowable: workflowable,
            actor: user,
            transition: 'submit_for_review'
          )
        end
      end

      def notify_assignee(user:, metadata:)
        # Notify the assignee if workflowable has one
        return unless workflowable.respond_to?(:assigned_to)
        return unless workflowable.assigned_to
        return if workflowable.assigned_to.id == user.id

        Bim::Collaboration::NotificationService.notify_workflow_transition(
          user: workflowable.assigned_to,
          workflowable: workflowable,
          actor: user,
          transition: 'assigned'
        )
      end

      def notify_creator(user:, metadata:)
        # Notify the creator
        creator = if workflowable.respond_to?(:created_by) && workflowable.created_by
                    workflowable.created_by
                  elsif workflowable.respond_to?(:user) && workflowable.user
                    workflowable.user
                  end

        return unless creator
        return if creator.id == user.id

        Bim::Collaboration::NotificationService.notify_workflow_transition(
          user: creator,
          workflowable: workflowable,
          actor: user,
          transition: 'status_update'
        )
      end

      def auto_assign(user:, metadata:)
        # Auto-assign to user if workflowable supports it
        return unless workflowable.respond_to?(:assigned_to=)

        workflowable.update_column(:assigned_to_id, user.id)
      end

      def create_notification(user:, metadata:)
        # Create in-app notification
        Rails.logger.info "Workflow transition notification: #{workflowable.class.name} ##{workflowable.id} transitioned to #{workflowable.workflow_state}"
      end

      # Custom error classes
      class InvalidTransitionError < StandardError; end
      class GuardFailedError < StandardError; end
      class PermissionError < StandardError; end
    end
  end
end
