class Notification < ApplicationRecord
  enum reason: { mentioned: 0, assigned: 1, watched: 2, subscribed: 3 }

  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'
  belongs_to :context, polymorphic: true
  belongs_to :resource, polymorphic: true

  scope :recipient, ->(user) { where(recipient_id: user.is_a?(User) ? user.id : user) }
end
