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
module Users
  module Sessions
    class TableComponent < ::OpPrimer::BorderBoxTableComponent
      columns :browser, :device, :expires_on, :updated_at
      sortable_columns :last_connection, :expires_on
      options :current_session, :current_token
      mobile_columns :browser, :device, :expires_on, :updated_at

      def mobile_title
        t("users.sessions.title")
      end

      def has_actions?
        true
      end

      def headers
        [
          [:browser, { caption: I18n.t("users.sessions.browser") }],
          [:device, { caption: I18n.t("users.sessions.device") }],
          [:expires_on, { caption: I18n.t("users.sessions.expires") }],
          [:updated_at, { caption: I18n.t("users.sessions.last_connection") }]
        ]
      end
    end
  end
end
