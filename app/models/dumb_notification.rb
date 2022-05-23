class DumbNotification < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  def self.recipient(user)
    where(recipient: user)
  end

  def reason
    Notification::REASONS.invert[(id || 0) % 9]
  end
end
