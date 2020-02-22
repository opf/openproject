module ::TwoFactorAuthentication
  module My
    class RememberCookieController < ::ApplicationController
      # Remmeber token functionality
      include ::TwoFactorAuthentication::RememberToken

      # Ensure user is logged in
      before_action :require_login

      layout 'my'
      menu_item :two_factor_authentication

      ##
      # Remove the remember token
      def destroy
        clear_remember_token!
        flash[:notice] = I18n.t('two_factor_authentication.remember.cookie_removed')
        redirect_to my_2fa_devices_path
      end
    end
  end
end
