module ::TwoFactorAuthentication
  module Devices
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::PasswordHelper

      def device
        model
      end

      def row_css_class
        is_default = "blocked" if device.default

        ["mobile-otp--two-factor-device-row", is_default].compact.join(" ")
      end

      def device_type
        device.identifier
      end

      def default
        if device.default
          op_icon 'icon-yes'
        else
          '-'
        end
      end

      def confirmed
        if device.active
          op_icon 'icon-yes'
        elsif table.self_table?
          link_to t('two_factor_authentication.devices.confirm_now'),
                  { controller: table.target_controller, action: :confirm, device_id: device.id }

        else
          op_icon 'icon-no'
        end
      end

      ###

      def button_links
        links = [delete_link]
        links << make_default_link unless device.default

        links
      end

      def make_default_link
        password_confirmation_form_for(
            device,
            url: { controller: table.target_controller, action: :make_default, device_id: device.id },
            method: :post,
            html: { id: 'two_factor_make_default_form', class: 'form--inline' }
        ) do |f|
          f.submit I18n.t(:button_make_default),
                   class: 'button--link two-factor--mark-default-button'
        end
      end

      def delete_link
        title =
          if deletion_blocked?
            I18n.t('two_factor_authentication.devices.is_default_cannot_delete')
          else
            I18n.t(:button_delete)
          end

        password_confirmation_form_for(
          device,
          url: { controller: table.target_controller, action: :destroy, device_id: device.id },
          method: :delete,
          html: { id: 'two_factor_delete_form', class: '' }
        ) do |f|
          f.submit I18n.t(:button_delete),
                   class: 'button--link two-factor--delete-button',
                   disabled: deletion_blocked?,
                   title: title
        end
      end

      def deletion_blocked?
        return false if table.admin_table?

        device.default && table.enforced?
      end

      def column_css_class(column)
        if device.default
          'mobile-otp--device-default'
        end
      end
    end
  end
end
