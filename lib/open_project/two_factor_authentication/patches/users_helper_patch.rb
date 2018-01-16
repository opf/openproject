module OpenProject::TwoFactorAuthentication::Patches
  module UsersHelperPatch
    def self.included(base) # :nodoc:
      base.prepend(InstanceMethods)
    end

    module InstanceMethods
      # Adds a 2FA tab to the user administration page
      def user_settings_tabs
        # Core defined data
        if OpenProject::TwoFactorAuthentication::TokenStrategyManager.enabled?
          super + [{ name: 'two_factor_authentication', partial: 'users/two_factor_authentication', label: 'two_factor_authentication.label_two_factor_authentication' }]
        else
          super
        end
      end
    end
  end
end
