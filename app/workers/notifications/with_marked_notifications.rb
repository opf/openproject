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

# Because we mark the notifications as read even though they in fact aren't, we do it in a transaction
# so that the change is rolled back in case of an error.
module Notifications
  module WithMarkedNotifications
    extend ActiveSupport::Concern

    included do
      private

      def with_marked_notifications(notification_ids)
        Notification.transaction do
          # It might be decided by the callers that the notifications should not be sent after all which
          # is signaled by `nil`. This happens e.g. for work packages where users might have disabled the
          # immediate_reminders for mentioned.
          was_sent = yield

          mark_notifications_sent(notification_ids, was_sent.present? ? !!was_sent : nil)

          was_sent
        end
      end

      def mark_notifications_sent(notification_ids, was_sent)
        Notification
          .where(id: Array(notification_ids))
          .update_all(notification_marked_attribute => was_sent, updated_at: Time.current)
      end
    end
  end
end
