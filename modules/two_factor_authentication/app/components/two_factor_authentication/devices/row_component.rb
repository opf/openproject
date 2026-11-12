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

module ::TwoFactorAuthentication
  module Devices
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def device
        model
      end

      def row_css_class
        "mobile-otp--two-factor-device-row"
      end

      def device_type
        device.identifier
      end

      def default
        if device.default
          render(Primer::Beta::Octicon.new(icon: :check))
        else
          "-"
        end
      end

      def active
        if device.active
          render(Primer::Beta::Octicon.new(icon: :check))
        elsif table.self_table?
          "-"
        else
          render(Primer::Beta::Octicon.new(icon: :x))
        end
      end

      ###

      def button_links
        [menu_button]
      end

      def menu_button
        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(
            icon: "kebab-horizontal",
            scheme: :invisible,
            "aria-label": t(:label_actions),
            test_selector: "two-factor--actions-button"
          )

          make_default_action(menu)
          make_active_action(menu) if table.self_table?
          delete_action(menu)
        end
      end

      def make_default_action(menu)
        menu.with_item(
          label: t(:button_make_default),
          tag: :button,
          disabled: device.default,
          href: helpers.url_for(controller: table.target_controller, action: :make_default, device_id: device.id),
          form_arguments: {
            method: :post,
            id: "two_factor_make_default_form",
            data: helpers.password_confirmation_data_attribute({})
          },
          test_selector: "two-factor--make-default-button",
          "aria-label": t(:button_make_default)
        )
      end

      def make_active_action(menu)
        menu.with_item(
          label: I18n.t(:button_make_active),
          tag: :a,
          disabled: device.active,
          href: helpers.url_for(controller: table.target_controller, action: :confirm, device_id: device.id),
          test_selector: "two-factor--make-active-button",
          "aria-label": t("two_factor_authentication.devices.confirm_now")
        )
      end

      def delete_action(menu)
        menu.with_item(
          label: t(:button_remove),
          scheme: :danger,
          tag: :button,
          disabled: deletion_blocked?,
          href: helpers.url_for(controller: table.target_controller, action: :destroy, device_id: device.id),
          form_arguments: {
            method: :delete,
            id: "two_factor_delete_form",
            data: helpers.password_confirmation_data_attribute({})
          },
          test_selector: "two-factor--delete-button",
          "aria-label": if deletion_blocked?
                          t("two_factor_authentication.devices.is_default_cannot_delete")
                        else
                          t(:button_delete)
                        end
        )
      end

      def deletion_blocked?
        return false if table.admin_table?

        device.default && table.enforced?
      end
    end
  end
end
