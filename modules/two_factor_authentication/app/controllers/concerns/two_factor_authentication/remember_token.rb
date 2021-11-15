module ::TwoFactorAuthentication
  module RememberToken
    extend ActiveSupport::Concern

    included do
      helper_method :has_valid_2fa_remember_token?
      helper_method :remember_2fa_enabled?
      helper_method :remember_2fa_days
    end

    ##
    # Check for valid 2FA autologin cookie and log in the user
    # if that's the case
    def perform_2fa_authentication_with_remember(service)
      if has_valid_2fa_remember_token?(@authenticated_user)
        complete_stage_redirect
      else
        perform_2fa_authentication service
      end
    end

    ##
    # Set a 2FA autologin cookie for the user (if supported).
    def set_remember_token!
      return unless remember_2fa_enabled?
      return unless params[:remember_me].present?

      cookies.encrypted[remember_cookie_name] = {
        value: new_token!(@authenticated_user),
        httponly: true,
        expires: remember_2fa_days.days.from_now,
        secure: Setting.protocol == 'https'
      }
    end

    ##
    # Remove the 2FA autologin cookie
    # and all potentially stored tokens
    def clear_remember_token!(user = current_user)
      cookies.delete remember_cookie_name

      ::TwoFactorAuthentication::RememberedAuthToken
          .where(user: user)
          .delete_all
    end

    def remember_2fa_enabled?
      remember_2fa_days > 0
    end

    ##
    # Return whether for the given user,
    # any valid remember tokens exist (not necessary in this session!)
    def any_remember_token_present?(user = current_user)
      return false unless remember_2fa_enabled?

      ::TwoFactorAuthentication::RememberedAuthToken
        .not_expired
        .where(user: user)
        .exists?
    end

    ##
    # Return whether the user has a valid remember token
    # that is identified by his cookie value.
    def has_valid_2fa_remember_token?(user = current_user)
      return false unless remember_2fa_enabled?

      token = get_2fa_remember_token(user)
      token.present? && !token.expired?
    end

    ##
    # Try to read a Remember token from the cookie
    def get_2fa_remember_token(user)
      value = cookies.encrypted[remember_cookie_name]
      return false unless value.present?

      ::TwoFactorAuthentication::RememberedAuthToken
        .where(user: user)
        .find_by_plaintext_value value
    end

    def remember_2fa_days
      OpenProject::TwoFactorAuthentication::TokenStrategyManager.allow_remember_for_days
    end

    private

    def remember_cookie_name
      :op2fa_remember_token
    end

    def new_token!(user)
      ::TwoFactorAuthentication::RememberedAuthToken.create_and_return_value(user)
    end
  end
end
