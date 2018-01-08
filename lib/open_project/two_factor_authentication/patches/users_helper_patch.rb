module OpenProject::TwoFactorAuthentication::Patches
  module UsersHelperPatch
    def self.included(base) # :nodoc:
      base.prepend(InstanceMethods)

      base.class_eval do
        alias_method :user_settings_tabs_without_2fa, :user_settings_tabs
        alias_method :user_settings_tabs, :user_settings_tabs_with_2fa
      end
    end

    module InstanceMethods
      # Adds a 2FA tab to the user administration page
      def user_settings_tabs_with_2fa
        # Core defined data
        if OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?
          user_settings_tabs_without_2fa + [{ name: 'two_factor_authentication', partial: 'users/two_factor_authentication', label: 'two_factor_authentication.label_two_factor_authentication' }]
        else
          user_settings_tabs_without_2fa
        end
      end
    end
  end
end
