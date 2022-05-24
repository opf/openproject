class DumbNotification < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  after_create_commit do
    broadcast_append_to('notification_center', target: 'notifications_feed', partial: "notifications/notification", locals: { notification: self })
  end

  after_update_commit do
    broadcast_replace_to('notification_center', target: self, partial: "notifications/notification", locals: { notification: self })
  end

  after_destroy_commit do
    broadcast_remove_to('notification_center', target: self)
  end

  def self.recipient(user)
    where(recipient: user)
  end

  def reason
    Notification::REASONS.invert[(id || 0) % 9]
  end
end
