# frozen_string_literal: true

module Herfy
  module ControlCenter
    # Creates/updates the "Herfy Control Center" OIDC provider from env:
    #   HERFY_CC_ISSUER         public URL of Control Center (required)
    #   HERFY_CC_CLIENT_ID      app registered in Control Center (required)
    #   HERFY_CC_CLIENT_SECRET  its secret (required)
    #   HERFY_CC_SCOPE          default "openid profile email roles"
    #   HERFY_CC_DISPLAY_NAME   default "Herfy Control Center"
    #   HERFY_CC_SYNC_GROUPS    default true
    module Provisioner
      module_function

      def configured?
        %w[HERFY_CC_ISSUER HERFY_CC_CLIENT_ID HERFY_CC_CLIENT_SECRET].all? { |k| ENV[k].present? }
      end

      def call # rubocop:disable Metrics/AbcSize
        issuer = ENV.fetch("HERFY_CC_ISSUER").chomp("/")
        provider = OpenIDConnect::Provider.find_or_initialize_by(slug: PROVIDER_SLUG)
        provider.display_name = ENV.fetch("HERFY_CC_DISPLAY_NAME", "Herfy Control Center")
        provider.creator ||= User.system
        provider.oidc_provider = "custom"
        provider.metadata_url = "#{issuer}/.well-known/openid-configuration"
        provider.issuer = issuer
        provider.client_id = ENV.fetch("HERFY_CC_CLIENT_ID")
        provider.client_secret = ENV.fetch("HERFY_CC_CLIENT_SECRET")
        provider.scope = ENV.fetch("HERFY_CC_SCOPE", "openid profile email roles")
        provider.mapping_login = "email"
        provider.mapping_email = "email"
        provider.mapping_first_name = "given_name"
        provider.mapping_last_name = "family_name"
        provider.sync_groups = ENV.fetch("HERFY_CC_SYNC_GROUPS", "true") == "true"
        provider.groups_claim = "groups"
        meta = JSON.parse(Net::HTTP.get(URI(provider.metadata_url)))
        %w[authorization_endpoint token_endpoint userinfo_endpoint jwks_uri].each do |k|
          provider.public_send(:"#{k}=", meta.fetch(k))
        end
        provider.available = true
        provider.save!(validate: false)
        Herfy::ControlCenter.ensure_custom_fields!
        provider
      end
    end
  end
end
