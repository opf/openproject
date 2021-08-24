class NotificationSetting < ApplicationRecord
  enum channel: { in_app: 0, mail: 1, mail_digest: 2 }

  belongs_to :project
  belongs_to :user

  include Scopes::Scoped
  scopes :applicable

  validates :channel, uniqueness: { scope: %i[project user] }
end
