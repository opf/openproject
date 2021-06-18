class NotificationSetting < ApplicationRecord
  enum channel: { in_app: 0, mail: 1 }

  belongs_to :project
  belongs_to :user

  validates :channel, uniqueness: { scope: %i[project user] }
end
