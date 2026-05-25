# frozen_string_literal: true

class Mngt::PushSubscription < ApplicationRecord
  self.table_name = "mngt_push_subscriptions"

  belongs_to :user

  validates :endpoint, :p256dh, :auth, presence: true
  validates :endpoint, uniqueness: true
end
