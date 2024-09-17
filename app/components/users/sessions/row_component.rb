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

module Users
  module Sessions
    class RowComponent < ::RowComponent
      property :firstname, :lastname
      delegate :current_session, to: :table

      def session
        model
      end

      def session_data
        @session_data ||= session.data.with_indifferent_access
      end

      def current?
        @current ||= session.current?(current_session)
      end

      def is_current # rubocop:disable Naming/PredicateName
        if current?
          helpers.op_icon "icon-yes"
        end
      end

      def device
        session_data[:platform] || I18n.t("users.sessions.unknown_os")
      end

      def browser
        name = session_data[:browser] || "unknown browser"
        version = session_data[:browser_version]
        "#{name} #{version ? "(Version #{version})" : ''}"
      end

      def platform
        session_data[:platform] || "unknown platform"
      end

      def updated_at
        if current?
          I18n.t("users.sessions.current")
        else
          helpers.format_time session.updated_at
        end
      end

      def button_links
        [delete_link].compact
      end

      def delete_link
        return if current?

        link_to(
          helpers.op_icon("icon icon-delete"),
          { controller: "/my/sessions", action: "destroy", id: session },
          class: "button--link",
          role: :button,
          method: :delete,
          data: { confirm: I18n.t(:text_are_you_sure), disable_with: I18n.t(:label_loading) },
          title: I18n.t(:button_delete)
        )
      end
    end
  end
end
