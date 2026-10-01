# frozen_string_literal: true

module Herfy
  # Carries Control Center's claims from the OmniAuth callback (user may not
  # exist yet) to the point where the user is logged in and persisted.
  class ControlCenterHook < OpenProject::Hook::Listener
    SESSION_KEY = "omniauth.herfy_claims" # also listed in the openid_connect engine's retain_from_session

    def omniauth_user_authorized(context)
      return unless context.dig(:auth_hash, :provider).to_s == Herfy::ControlCenter::PROVIDER_SLUG

      raw = context.dig(:auth_hash, :extra, :raw_info)
      context.fetch(:controller).session[SESSION_KEY] = Herfy::ControlCenter.claims_from_oidc(raw) if raw
      nil
    end

    def user_logged_in(context)
      claims = context.fetch(:session).delete(SESSION_KEY)
      Herfy::ControlCenter.apply_claims(context.fetch(:user), claims) if claims
    rescue StandardError => e
      # A claims problem must never lock people out of OpenProject.
      Rails.logger.error("[herfy] control center claim sync failed: #{e.class}: #{e.message}")
    end
  end
end
