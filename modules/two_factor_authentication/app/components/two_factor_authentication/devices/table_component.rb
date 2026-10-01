# frozen_string_literal: true

module ::TwoFactorAuthentication
  module Devices
    class TableComponent < ::OpPrimer::BorderBoxTableComponent
      options :admin_table
      columns :device_type, :default, :active
      mobile_labels :default, :active

      def mobile_title
        I18n.t("two_factor_authentication.label_devices")
      end

      def has_actions?
        true
      end

      def self_table?
        !admin_table
      end

      def admin_table?
        admin_table
      end

      def target_controller
        if self_table?
          "two_factor_authentication/my/two_factor_devices"
        else
          "two_factor_authentication/users/two_factor_devices"
        end
      end

      delegate :enforced?, to: :strategy_manager

      def strategy_manager
        ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
      end

      def blank_title
        if admin_table?
          I18n.t "two_factor_authentication.admin.no_devices_for_user"
        else
          I18n.t "two_factor_authentication.devices.not_existing"
        end
      end

      def headers
        [
          [:device_type, { caption: I18n.t("two_factor_authentication.label_device_type") }],
          [:default, { caption: I18n.t(:label_default) }],
          [:active, { caption: I18n.t(:label_active) }]
        ]
      end
    end
  end
end
