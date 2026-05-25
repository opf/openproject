# frozen_string_literal: true

module Mngt
  class SendNotificationPushJob < ApplicationJob
    queue_as :default

    def perform(notification_id)
      Mngt::NotificationPushService.call(notification_id)
    end
  end
end
