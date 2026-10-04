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
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      delegate :current_session, :current_token, to: :table

      def record
        model
      end

      def session?
        record.is_a?(::Sessions::UserSession)
      end

      def token?
        record.is_a?(::Token::AutoLogin)
      end

      def current?
        (session? && record.current?(current_session)) || (token? && record == current_token)
      end

      def browser
        return I18n.t("users.sessions.unknown_browser") unless session? || token?

        data = record.data.with_indifferent_access
        name = data[:browser] || I18n.t("users.sessions.unknown_browser")
        version = data[:browser_version]
        version ? "#{name} (Version #{version})" : name
      end

      def device
        return I18n.t("users.sessions.unknown_os") unless session? || token?

        record.data.with_indifferent_access[:platform] || I18n.t("users.sessions.unknown_os")
      end

      def expires_on
        if token?
          expires = record.expires_on || (record.created_at + Setting.autologin.days)
          render(OpPrimer::RelativeTimeComponent.new(datetime: user_time_zone(expires), prefix: I18n.t(:label_on)))
        else
          I18n.t("users.sessions.browser_session")
        end
      end

      def updated_at
        if current?
          I18n.t("users.sessions.current")
        elsif token?
          helpers.format_time(record.created_at)
        else
          record.respond_to?(:updated_at) ? helpers.format_time(record.updated_at) : "-"
        end
      end

      def button_links
        [delete_button]
      end

      def row_css_class
        "session-row"
      end

      private

      def delete_button
        return if current?

        render(
          Primer::Beta::Button.new(
            scheme: :danger,
            test_selector: "session-revoke-button",
            tag: :a,
            href: revoke_path,
            data: {
              turbo_method: :delete,
              turbo_confirm: I18n.t("users.sessions.deletion_warning"),
              turbo_submits_with: I18n.t(:label_loading)
            }
          )
        ) do |button|
          button.with_leading_visual_icon(icon: :"sign-out")

          I18n.t(:button_revoke)
        end
      end

      def revoke_path
        if token?
          url_for(controller: "/my/auto_login_tokens", action: "destroy", id: record)
        else
          url_for(controller: "/my/sessions", action: "destroy", id: record)
        end
      end

      def user_time_zone(time)
        helpers.in_user_zone(time)
      end
    end
  end
end
