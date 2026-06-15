# frozen_string_literal: true

module ::TwoFactorAuthentication
  module My
    class RememberCookieController < ::ApplicationController
      # Remember token functionality
      include ::TwoFactorAuthentication::RememberToken

      # Ensure user is logged in
      before_action :require_login
      no_authorization_required! :destroy

      layout "my"
      menu_item :security

      ##
      # Remove the remember token
      def destroy
        clear_remember_token!
        flash[:notice] = I18n.t("two_factor_authentication.remember.cookie_removed")
        redirect_to my_security_path, status: :see_other
      end
    end
  end
end
