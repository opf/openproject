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

module Members::Concerns::NotificationSender
  extend ActiveSupport::Concern

  included do
    def send_notification(member)
      OpenProject::Notifications.send(event_type,
                                      member:,
                                      message: notification_message,
                                      send_notifications: send_notifications?)
    end

    def set_attributes_params(params)
      super.except(:notification_message, :send_notifications)
    end

    def notification_message
      params[:notification_message]
    end

    def send_notifications?
      # Because this class is mixed in in a service using around_call hook, it
      # can not rely on Service#perform method setting the send_notifications
      # configuration. It would be nice to unify both.
      params.fetch(:send_notifications, Journal::NotificationConfiguration.active?)
    end

    def event_type
      raise NotImplementedError
    end
  end
end
