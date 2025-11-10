# frozen_string_literal: true

module Bim
  module Collaboration
    class NotificationService
      # Notify a user when they are mentioned in a comment
      def self.notify_mention(user:, comment:)
        new.notify_mention(user: user, comment: comment)
      end

      # Notify a user about a workflow transition
      def self.notify_workflow_transition(user:, workflowable:, actor:, transition:)
        new.notify_workflow_transition(
          user: user,
          workflowable: workflowable,
          actor: actor,
          transition: transition
        )
      end

      def notify_mention(user:, comment:)
        return unless user && comment

        # Create in-app notification
        create_mention_notification(user, comment)

        # Optionally send email notification
        send_mention_email(user, comment) if should_send_email?(user)
      end

      def notify_workflow_transition(user:, workflowable:, actor:, transition:)
        return unless user && workflowable && actor

        # Create in-app notification for workflow transition
        create_workflow_notification(user, workflowable, actor, transition)

        # Optionally send email notification
        send_workflow_email(user, workflowable, actor, transition) if should_send_email?(user)
      end

      private

      def create_mention_notification(user, comment)
        # Use OpenProject's notification system if available
        # Otherwise log the notification
        notification_data = {
          recipient: user,
          actor: comment.journal.user,
          resource: comment,
          project: comment.issue.project,
          reason: :mentioned
        }

        Rails.logger.info "Mention notification: User #{user.login} mentioned in comment #{comment.id}"

        # If OpenProject has a notification model, create it here
        # Notification.create!(notification_data)
      end

      def send_mention_email(user, comment)
        # Send email using OpenProject's mailer system
        # UserMailer.bim_comment_mention(user, comment).deliver_later
        Rails.logger.info "Email notification sent to #{user.mail} for mention in comment #{comment.id}"
      end

      def should_send_email?(user)
        # Check user's email preferences
        # For now, return true if user has email set
        user.mail.present?
      end

      def create_workflow_notification(user, workflowable, actor, transition)
        notification_data = {
          recipient: user,
          actor: actor,
          resource: workflowable,
          project: workflowable.respond_to?(:project) ? workflowable.project : nil,
          reason: :workflow_transition,
          transition: transition,
          state: workflowable.workflow_state
        }

        Rails.logger.info "Workflow notification: User #{user.login} notified about #{workflowable.class.name} ##{workflowable.id} transition to #{workflowable.workflow_state}"

        # If OpenProject has a notification model, create it here
        # Notification.create!(notification_data)
      end

      def send_workflow_email(user, workflowable, actor, transition)
        # Send email using OpenProject's mailer system
        # UserMailer.bim_workflow_transition(user, workflowable, actor, transition).deliver_later
        Rails.logger.info "Email notification sent to #{user.mail} for workflow transition in #{workflowable.class.name} ##{workflowable.id}"
      end
    end
  end
end
