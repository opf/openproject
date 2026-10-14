# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Notifications
  # Creates a notification requested via the API. Currently, only mentions are supported,
  # i.e. notifications for a user (recipient) being mentioned by the current user
  # in a resource, e.g. a document. Contrary to notifications created by
  # Notifications::CreateFromModelService, these notifications are not bound to a journal.
  #
  # Mentioning is validated by Notifications::CreateMentionFromApiContract. If the mention is valid
  # but the recipient is not to be notified, because the recipient mentioned themselves
  # or has disabled notifications for being mentioned, a successful result without a
  # notification is returned.
  class CreateFromApiService
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    # @param reason [String, Symbol] has to be "mentioned"
    # @param resource_type [String] class name of the resource, e.g. "Document"
    # @param resource_id [Integer, String]
    # @param recipient_id [Integer, String]
    def call(reason:, resource_type:, resource_id:, recipient_id:)
      notification = build_notification(reason:, resource_type:, resource_id:, recipient_id:)

      contract = Notifications::CreateMentionFromApiContract.new(notification, user)

      return ServiceResult.failure(result: notification, errors: contract.errors) unless contract.valid?
      return ServiceResult.success if skip_notification?(notification)

      Notifications::CreateService
        .new(user:, model: notification)
        .call
    end

    private

    def build_notification(reason:, resource_type:, resource_id:, recipient_id:)
      reason = reason.to_s
      strategy = Notifications::CreateFromModelService.strategy_for(resource_type)

      Notification.new(
        reason: Notification.reasons.key?(reason) ? reason : nil,
        # Only types having a strategy are kept. That way, arbitrary (non existing) class names,
        # which would fail to load the resource, never end up on the notification. The contract
        # reports the missing support for the resource type.
        resource_type: strategy ? resource_type : nil,
        resource_id:,
        recipient_id:,
        actor: user,
        journal: nil,
        read_ian: strategy&.supports_ian?(reason) ? false : nil,
        mail_alert_sent: nil,
        mail_reminder_sent: nil
      )
    end

    def skip_notification?(notification)
      notification.recipient == user ||
        !mention_notification_enabled?(notification)
    end

    def mention_notification_enabled?(notification)
      NotificationSetting
        .enabled_for(NotificationSetting::MENTIONED, notification.resource.project)
        .exists?(user: notification.recipient)
    end
  end
end
