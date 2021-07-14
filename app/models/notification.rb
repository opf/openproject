class Notification < ApplicationRecord
  enum reason_ian: { mentioned: 0, involved: 1, watched: 2, subscribed: 3 }, _prefix: :ian
  enum reason_mail: { mentioned: 0, involved: 1, watched: 2, subscribed: 3 }, _prefix: :mail
  enum reason_mail_digest: { mentioned: 0, involved: 1, watched: 2, subscribed: 3 }, _prefix: :mail_digest

  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :project
  belongs_to :journal
  belongs_to :resource, polymorphic: true

  scope :recipient, ->(user) { where(recipient_id: user.is_a?(User) ? user.id : user) }

  include Scopes::Scoped
  scopes :mail_digest_before
end
