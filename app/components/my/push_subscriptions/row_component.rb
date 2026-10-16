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
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      delegate :current_session, to: :table

      def row_css_class
        "push-subscription-row"
      end

      def row_data
        { test_selector: "push-subscription-row" }
      end

      def browser
        return browser_label unless current?

        safe_join(
          [
            browser_label,
            render(Primer::Beta::Text.new(classes: "sr-only")) { ", " },
            render(Primer::Beta::Label.new(scheme: :accent, ml: 2)) { I18n.t("my_account.push_notifications.this_session") }
          ]
        )
      end

      def device
        session_data[:platform] || I18n.t("users.sessions.unknown_os")
      end

      def button_links
        [revoke_button].compact
      end

      private

      def session_data
        @session_data ||= model.session.data.with_indifferent_access
      end

      def current?
        model.session.current?(current_session)
      end

      def browser_label
        name = session_data[:browser] || I18n.t("users.sessions.unknown_browser")
        version = session_data[:browser_version]

        version ? I18n.t("users.sessions.browser_with_version", name:, version:) : name
      end

      def revoke_button
        return if current?

        render(
          Primer::Beta::Button.new(
            scheme: :danger,
            tag: :a,
            href: helpers.my_push_subscription_path(model),
            test_selector: "push-subscription-revoke-button",
            aria: { label: I18n.t("my_account.push_notifications.revoke_device", device: browser_label) },
            data: {
              turbo_method: :delete,
              turbo_confirm: I18n.t("my_account.push_notifications.revoke_confirm", device: browser_label),
              turbo_submits_with: I18n.t(:label_loading)
            }
          )
        ) do |button|
          button.with_leading_visual_icon(icon: :"sign-out")

          I18n.t("my_account.push_notifications.revoke")
        end
      end
    end
  end
end
