# frozen_string_literal: true

module Bim
  module Seeds
    class WorkflowTemplates
      def self.seed!
        new.seed!
      end

      def seed!
        Rails.logger.info "Seeding default BIM workflow templates..."

        seed_issue_review_workflow
        seed_clash_resolution_workflow
        seed_element_approval_workflow

        Rails.logger.info "BIM workflow templates seeded successfully"
      end

      private

      def seed_issue_review_workflow
        template = ::Bim::WorkflowTemplate.find_or_initialize_by(
          name: 'Standard Issue Review',
          workflow_type: :issue_review,
          is_default: true,
          project_id: nil
        )

        template.update!(
          description: 'Standard workflow for reviewing and approving BCF issues',
          active: true,
          states: [
            {
              name: 'draft',
              label: 'Draft',
              color: '#gray',
              initial: true,
              description: 'Issue is being drafted'
            },
            {
              name: 'submitted',
              label: 'Submitted',
              color: '#blue',
              description: 'Issue has been submitted for review'
            },
            {
              name: 'in_review',
              label: 'In Review',
              color: '#purple',
              description: 'Issue is being reviewed by team'
            },
            {
              name: 'changes_requested',
              label: 'Changes Requested',
              color: '#orange',
              description: 'Reviewer requested changes'
            },
            {
              name: 'approved',
              label: 'Approved',
              color: '#green',
              final: true,
              description: 'Issue has been approved'
            },
            {
              name: 'rejected',
              label: 'Rejected',
              color: '#red',
              final: true,
              description: 'Issue has been rejected'
            }
          ],
          transitions: [
            {
              name: 'submit',
              from: 'draft',
              to: 'submitted',
              label: 'Submit for Review',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'start_review',
              from: 'submitted',
              to: 'in_review',
              label: 'Start Review',
              actions: ['auto_assign'],
              required_role: 'member'
            },
            {
              name: 'request_changes',
              from: 'in_review',
              to: 'changes_requested',
              label: 'Request Changes',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'resubmit',
              from: 'changes_requested',
              to: 'in_review',
              label: 'Resubmit',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'approve',
              from: 'in_review',
              to: 'approved',
              label: 'Approve',
              guard: 'can_approve?',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'reject',
              from: 'in_review',
              to: 'rejected',
              label: 'Reject',
              guard: 'can_reject?',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'reopen',
              from: '*',
              to: 'draft',
              label: 'Reopen',
              required_role: 'manager'
            }
          ],
          configuration: {
            notifications_enabled: true,
            auto_assignment: true,
            require_comments_on_rejection: true
          }
        )

        Rails.logger.info "  ✓ Issue Review workflow template created/updated"
      end

      def seed_clash_resolution_workflow
        template = ::Bim::WorkflowTemplate.find_or_initialize_by(
          name: 'Clash Resolution',
          workflow_type: :clash_resolution,
          is_default: true,
          project_id: nil
        )

        template.update!(
          description: 'Workflow for detecting, reviewing, and resolving clashes',
          active: true,
          states: [
            {
              name: 'new',
              label: 'New',
              color: '#yellow',
              initial: true,
              description: 'Clash detected, not yet reviewed'
            },
            {
              name: 'active',
              label: 'Active',
              color: '#blue',
              description: 'Clash acknowledged, assigned for resolution'
            },
            {
              name: 'under_investigation',
              label: 'Under Investigation',
              color: '#purple',
              description: 'Clash is being investigated'
            },
            {
              name: 'resolved',
              label: 'Resolved',
              color: '#green',
              description: 'Clash has been resolved'
            },
            {
              name: 'approved',
              label: 'Approved as Acceptable',
              color: '#teal',
              description: 'Clash approved as acceptable (minor/false positive)'
            },
            {
              name: 'verified',
              label: 'Verified',
              color: '#green',
              final: true,
              description: 'Resolution verified and closed'
            },
            {
              name: 'closed',
              label: 'Closed',
              color: '#gray',
              final: true,
              description: 'Clash closed (no longer relevant)'
            }
          ],
          transitions: [
            {
              name: 'acknowledge',
              from: 'new',
              to: 'active',
              label: 'Acknowledge',
              actions: ['auto_assign'],
              required_role: 'member'
            },
            {
              name: 'investigate',
              from: 'active',
              to: 'under_investigation',
              label: 'Start Investigation',
              actions: ['notify_assignee'],
              required_role: 'member'
            },
            {
              name: 'mark_resolved',
              from: 'under_investigation',
              to: 'resolved',
              label: 'Mark as Resolved',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'approve_acceptable',
              from: 'under_investigation',
              to: 'approved',
              label: 'Approve as Acceptable',
              guard: 'can_approve?',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'verify',
              from: 'resolved',
              to: 'verified',
              label: 'Verify Resolution',
              guard: 'can_approve?',
              actions: ['notify_assignee'],
              required_role: 'manager'
            },
            {
              name: 'close',
              from: '*',
              to: 'closed',
              label: 'Close',
              required_role: 'manager'
            },
            {
              name: 'reopen',
              from: '*',
              to: 'active',
              label: 'Reopen',
              required_role: 'member'
            }
          ],
          configuration: {
            notifications_enabled: true,
            auto_assignment: true,
            severity_based_routing: true
          }
        )

        Rails.logger.info "  ✓ Clash Resolution workflow template created/updated"
      end

      def seed_element_approval_workflow
        template = ::Bim::WorkflowTemplate.find_or_initialize_by(
          name: 'Element Approval',
          workflow_type: :element_approval,
          is_default: true,
          project_id: nil
        )

        template.update!(
          description: 'Workflow for approving element design and construction readiness',
          active: true,
          states: [
            {
              name: 'pending',
              label: 'Pending',
              color: '#gray',
              initial: true,
              description: 'Element pending review'
            },
            {
              name: 'design_review',
              label: 'Design Review',
              color: '#blue',
              description: 'Element in design review'
            },
            {
              name: 'design_approved',
              label: 'Design Approved',
              color: '#teal',
              description: 'Design approved, pending construction approval'
            },
            {
              name: 'construction_review',
              label: 'Construction Review',
              color: '#purple',
              description: 'Element in construction readiness review'
            },
            {
              name: 'ready_for_construction',
              label: 'Ready for Construction',
              color: '#green',
              final: true,
              description: 'Element approved for construction'
            },
            {
              name: 'changes_required',
              label: 'Changes Required',
              color: '#orange',
              description: 'Element requires changes'
            },
            {
              name: 'on_hold',
              label: 'On Hold',
              color: '#yellow',
              description: 'Element approval on hold'
            }
          ],
          transitions: [
            {
              name: 'submit_for_design_review',
              from: 'pending',
              to: 'design_review',
              label: 'Submit for Design Review',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'approve_design',
              from: 'design_review',
              to: 'design_approved',
              label: 'Approve Design',
              guard: 'can_approve?',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'request_design_changes',
              from: 'design_review',
              to: 'changes_required',
              label: 'Request Design Changes',
              actions: ['notify_creator'],
              required_role: 'manager'
            },
            {
              name: 'resubmit_design',
              from: 'changes_required',
              to: 'design_review',
              label: 'Resubmit Design',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'submit_for_construction_review',
              from: 'design_approved',
              to: 'construction_review',
              label: 'Submit for Construction Review',
              actions: ['notify_reviewers'],
              required_role: 'member'
            },
            {
              name: 'approve_for_construction',
              from: 'construction_review',
              to: 'ready_for_construction',
              label: 'Approve for Construction',
              guard: 'can_approve?',
              actions: ['notify_creator', 'create_notification'],
              required_role: 'manager'
            },
            {
              name: 'hold',
              from: '*',
              to: 'on_hold',
              label: 'Put On Hold',
              required_role: 'manager'
            },
            {
              name: 'resume',
              from: 'on_hold',
              to: 'pending',
              label: 'Resume',
              required_role: 'manager'
            }
          ],
          configuration: {
            notifications_enabled: true,
            multi_stage_approval: true,
            require_sign_off: true
          }
        )

        Rails.logger.info "  ✓ Element Approval workflow template created/updated"
      end
    end
  end
end

# Execute seeding if run directly
Bim::Seeds::WorkflowTemplates.seed! if __FILE__ == $PROGRAM_NAME
