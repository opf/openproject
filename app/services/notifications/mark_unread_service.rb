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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Notifications
  class MarkUnreadService
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def call(journal:)
      return ServiceResult.failure(errors: { base: :error_unauthorized }) unless allowed?(journal)

      existing = Notification.where(journal:, recipient: user)

      if existing.exists?
        existing.update_all(read_ian: false, updated_at: Time.current)
        ServiceResult.success(result: existing.to_a)
      else
        create_notification(journal)
      end
    end

    private

    def allowed?(journal)
      user.logged? && journal.journable.visible?(user)
    end

    def create_notification(journal)
      Notifications::CreateService
        .new(user:)
        .call(recipient: user,
              resource: journal.journable,
              journal:,
              actor: journal.user,
              reason: :marked_as_unread,
              read_ian: false,
              mail_reminder_sent: nil,
              mail_alert_sent: nil)
    end
  end
end
