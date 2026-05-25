# frozen_string_literal: true

Rails.application.config.after_initialize do
  Notification.after_create_commit do |notification|
    next unless notification.recipient_id.present? &&
                Mngt::PushSubscription.exists?(user_id: notification.recipient_id)

    Mngt::SendNotificationPushJob.perform_later(notification.id)
  end
end
