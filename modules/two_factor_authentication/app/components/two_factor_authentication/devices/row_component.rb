# frozen_string_literal: true

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
