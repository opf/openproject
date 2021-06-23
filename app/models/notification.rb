class Notification < ApplicationRecord
  enum reason: { mentioned: 0, involved: 1, watched: 2, subscribed: 3 }

  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :project
  belongs_to :journal
  belongs_to :resource, polymorphic: true

  scope :recipient, ->(user) { where(recipient_id: user.is_a?(User) ? user.id : user) }
end
