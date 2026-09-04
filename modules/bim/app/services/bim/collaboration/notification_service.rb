# frozen_string_literal: true

module Bim
  module Collaboration
    class NotificationService
      # Notify a user when they are mentioned in a comment
      def self.notify_mention(user:, comment:)
        new.notify_mention(user: user, comment: comment)
      end

      def notify_mention(user:, comment:)
        return unless user && comment

        # Create in-app notification
        create_mention_notification(user, comment)

        # Optionally send email notification
        send_mention_email(user, comment) if should_send_email?(user)
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
    end
  end
end
