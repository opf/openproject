# frozen_string_literal: true

# Register Google OAuth2 as a login provider.
# OpenProject normally restricts SSO providers to Enterprise Edition via
# filtered_strategy?. We bypass that check specifically for google_oauth2
# when the credentials are configured.

# omniauth-google-oauth2 0.8.x calls JWT::Verify.verify_claims which was
# removed in jwt 3.0. Provide a minimal compatibility shim.
unless defined?(JWT::Verify)
  module JWT
    class Verify
      def self.verify_claims(payload, options)
        payload = payload.first if payload.is_a?(Array)

        if options[:verify_iss] && options[:iss]
          issuers = Array(options[:iss])
          raise JWT::InvalidIssuerError, "Invalid issuer. Expected #{issuers}, got #{payload['iss'].inspect}" \
            unless issuers.include?(payload["iss"])
        end

        if options[:verify_aud] && options[:aud]
          audiences = Array(options[:aud])
          payload_aud_arr = Array(payload["aud"])
          raise JWT::InvalidAudError, "Invalid audience" unless (audiences & payload_aud_arr).any?
        end

        if options[:verify_expiration] != false && payload["exp"]
          leeway = options[:leeway].to_i
          raise JWT::ExpiredSignature, "Token has expired" if payload["exp"].to_i < (Time.now.to_i - leeway)
        end

        if options[:verify_iat] && payload["iat"]
          raise JWT::InvalidIatError, "Invalid iat" unless payload["iat"].is_a?(Numeric)
        end

        true
      end
    end
  end
end

Rails.application.config.to_prepare do
  next unless ENV["GOOGLE_OAUTH_CLIENT_ID"].present? && ENV["GOOGLE_OAUTH_CLIENT_SECRET"].present?

  # Register in-memory strategy so the Google button shows on the login page.
  # The DB-backed OpenIDConnect::Provider is set to available: false to prevent
  # the OIDC module from registering a conflicting OmniAuth strategy.
  key = :google_oauth2
  unless OpenProject::Plugins::AuthPlugin.strategies.key?(key)
    OpenProject::Plugins::AuthPlugin.strategies[key] = [
      -> { [{ name: :google_oauth2, display_name: "Google" }] }
    ]
  end

  # Bypass the Enterprise Token check for google_oauth2.
  OpenProject::Plugins::AuthPlugin.singleton_class.prepend(Module.new do
    def filtered_strategy?(strategy_key, provider)
      return true if provider[:name]&.to_s == "google_oauth2"
      super
    end
  end)
end

# Ensure an AuthProvider DB record exists for google_oauth2 so that
# UserAuthProviderLinksSetter can link users to this provider after login.
Rails.application.config.after_initialize do
  next unless ENV["GOOGLE_OAUTH_CLIENT_ID"].present? && ENV["GOOGLE_OAUTH_CLIENT_SECRET"].present?

  begin
    unless AuthProvider.exists?(slug: "google_oauth2")
      system_user = SystemUser.first
      AuthProvider.create!(
        type: "OpenIDConnect::Provider",
        slug: "google_oauth2",
        display_name: "Google",
        available: false,
        creator: system_user,
        options: {
          oidc_provider: "google",
          client_id: ENV["GOOGLE_OAUTH_CLIENT_ID"],
          client_secret: ENV["GOOGLE_OAUTH_CLIENT_SECRET"],
          issuer: "https://accounts.google.com",
          authorization_endpoint: "https://accounts.google.com/o/oauth2/auth",
          token_endpoint: "https://oauth2.googleapis.com/token",
          userinfo_endpoint: "https://openidconnect.googleapis.com/v1/userinfo",
          jwks_uri: "https://www.googleapis.com/oauth2/v3/certs"
        }
      )
      Rails.logger.info "[mngt_google_auth] Created AuthProvider record for google_oauth2"
    end
  rescue => e
    Rails.logger.warn "[mngt_google_auth] Could not create AuthProvider for google_oauth2: #{e.message}"
  end
end
