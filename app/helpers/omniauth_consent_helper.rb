##
# Allows sending the user to their IdP's (identity provider) consent screen.
# This can be used to confirm the user is still logged in.
module OmniauthConsentHelper
  include LoginFlashHelper

  class OmniauthUserAuthorized < OpenProject::Hook::Listener
    def omniauth_user_authorized(context)
      auth_hash = context[:auth_hash]
      controller = context[:controller]

      if controller
        login_flash = Hash(controller.session[:login_flash])

        controller.flash[:omniauth_consent_user_uid] = auth_hash['uid'] if login_flash.delete :omniauth_consent_requested
      end
    end
  end

  def request_omniauth_consent(user)
    raise "User does not authenticate using OmniAuth" unless user.uses_external_authentication?

    login_flash[:omniauth_consent_requested] = true

    redirect_to "/auth/#{current_user.authentication_provider.downcase}?prompt=consent"
  end

  def omniauth_consent_given?(user)
    uid = flash[:omniauth_consent_user_uid].presence

    uid && String(user.identity_url).include?(uid)
  end
end