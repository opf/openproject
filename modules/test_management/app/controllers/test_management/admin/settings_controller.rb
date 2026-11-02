# frozen_string_literal: true

module TestManagement
  module Admin
    class SettingsController < ApplicationController
      layout "admin"
      menu_item :test_management

      before_action :require_admin

      # Keyboard shortcut switches (0019), see TestManagement::Hotkeys.enabled? / hints_enabled?.
      HOTKEY_SETTINGS = %w[hotkeys_enabled hotkey_hints_enabled].freeze

      # The Test Assistant's AI providers are saved providers since 0021 (AssistantProvidersController);
      # this page lists them.
      def show
        @settings = Hash(Setting.plugin_openproject_test_management).with_indifferent_access
        @providers = TestManagement::AssistantProvider.ordered.to_a
      end

      def update
        # Same direct Setting merge as other OpenProject admin settings controllers.
        Setting.plugin_openproject_test_management = Hash(Setting.plugin_openproject_test_management).merge(general_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to test_management_admin_settings_path
      end

      private

      # Display prefix and the keyboard shortcut switches (0019; checkboxes with a hidden "0", stored
      # as booleans, untouched when the form does not send them).
      def general_params
        values = params.permit(:default_display_prefix, *HOTKEY_SETTINGS).to_h
        HOTKEY_SETTINGS.each do |key|
          values[key] = ActiveModel::Type::Boolean.new.cast(values[key]) == true if values.key?(key)
        end
        values
      end
    end
  end
end
