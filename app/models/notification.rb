class Notification < ApplicationRecord
  REASONS = {
    mentioned: 0,
    involved: 1,
    watched: 2,
    subscribed: 3,
    commented: 4,
    created: 5,
    processed: 6,
    prioritized: 7,
    scheduled: 8
  }.freeze

  enum reason_ian: REASONS, _prefix: :ian
  enum reason_mail: REASONS, _prefix: :mail
  enum reason_mail_digest: REASONS, _prefix: :mail_digest

  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :project
  belongs_to :journal
  belongs_to :resource, polymorphic: true

  include Scopes::Scoped
  scopes :unsent_reminders_before,
         :unread_mail,
         :unread_mail_digest,
         :recipient
end
