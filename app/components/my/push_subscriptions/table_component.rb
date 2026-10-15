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

module My
  module PushSubscriptions
    class TableComponent < ::OpPrimer::BorderBoxTableComponent
      columns :browser, :device, :created_at
      options :current_session
      mobile_columns :browser, :device, :created_at

      def mobile_title
        t("my_account.push_notifications.title")
      end

      def has_actions?
        true
      end

      def blank_title
        t("my_account.push_notifications.no_devices")
      end

      def blank_description
        t("my_account.push_notifications.no_devices_description")
      end

      def blank_icon
        :bell
      end

      def headers
        [
          [:browser, { caption: I18n.t("users.sessions.browser") }],
          [:device, { caption: I18n.t("users.sessions.device") }],
          [:created_at, { caption: ::PushSubscription.human_attribute_name(:created_at) }]
        ]
      end
    end
  end
end
