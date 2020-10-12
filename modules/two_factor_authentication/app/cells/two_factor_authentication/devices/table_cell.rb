module ::TwoFactorAuthentication
  module Devices
    class TableCell < ::TableCell
      options :admin_table
      columns :device_type, :default, :confirmed

      def initial_sort
        [:login, :asc]
      end

      def self_table?
        !admin_table
      end

      def admin_table?
        admin_table
      end

      def target_controller
        if self_table?
          'two_factor_authentication/my/two_factor_devices'
        else
          'two_factor_authentication/users/two_factor_devices'
        end
      end

      def sortable?
        false
      end

      def inline_create_link
        if self_table?
          link_to({ controller: target_controller, action: :new },
                  class: 'budget-add-row wp-inline-create--add-link',
                  title: I18n.t('two_factor_authentication.devices.add_new')) do
              op_icon('icon icon-add')
          end
        end
      end

      def enforced?
        strategy_manager.enforced?
      end

      def strategy_manager
        ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
      end

      def empty_row_message
        if admin_table?
          I18n.t 'two_factor_authentication.admin.no_devices_for_user'
        else
          I18n.t 'two_factor_authentication.devices.not_existing'
        end
      end

      def headers
        [
            ['device_type', caption: I18n.t('two_factor_authentication.label_device_type')],
            ['default', caption: I18n.t(:label_default)],
            ['confirmed', caption: I18n.t(:label_confirmed)],
        ]
      end
    end
  end
end
