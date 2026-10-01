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
      ENDPOINTS = %w[authorization_endpoint token_endpoint userinfo_endpoint jwks_uri].freeze

      module_function

      def configured?
        %w[HERFY_CC_ISSUER HERFY_CC_CLIENT_ID HERFY_CC_CLIENT_SECRET].all? { |k| ENV[k].present? }
      end

      # force: true (rake setup) rewrites every setting. Boot (force: false) creates the
      # provider when missing and afterwards only refreshes issuer, endpoints and client
      # credentials, so edits made in the admin UI (mappings, scope, groups) survive restarts.
      def call(force: true) # rubocop:disable Metrics/AbcSize
        issuer = ENV.fetch("HERFY_CC_ISSUER").chomp("/")
        provider = OpenIDConnect::Provider.find_or_initialize_by(slug: PROVIDER_SLUG)
        fresh = provider.new_record?
        meta = discovery(issuer)

        provider.creator ||= User.system
        provider.oidc_provider = "custom"
        provider.metadata_url = "#{issuer}/.well-known/openid-configuration"
        provider.issuer = issuer
        provider.client_id = ENV.fetch("HERFY_CC_CLIENT_ID")
        provider.client_secret = ENV.fetch("HERFY_CC_CLIENT_SECRET")
        ENDPOINTS.each { |k| provider.public_send(:"#{k}=", meta.fetch(k)) }
        apply_defaults(provider) if fresh || force
        provider.available = true
        provider.save!
        Herfy::ControlCenter.ensure_custom_fields!
        provider
      end

      def apply_defaults(provider)
        provider.display_name = ENV.fetch("HERFY_CC_DISPLAY_NAME", "Herfy Control Center")
        provider.scope = ENV.fetch("HERFY_CC_SCOPE", "openid profile email roles")
        provider.mapping_login = "email"
        provider.mapping_email = "email"
        provider.mapping_first_name = "given_name"
        provider.mapping_last_name = "family_name"
        provider.sync_groups = ENV.fetch("HERFY_CC_SYNC_GROUPS", "true") == "true"
        provider.groups_claim = "groups"
      end

      # The discovery document is only trusted if it names the configured issuer and every
      # endpoint stays on the issuer's origin, so a poisoned or misconfigured document can't
      # redirect logins or the client secret to another host.
      def discovery(issuer)
        uri = URI("#{issuer}/.well-known/openid-configuration")
        raise ArgumentError, "HERFY_CC_ISSUER must be http(s)" unless uri.is_a?(URI::HTTP)

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
          http.get(uri.request_uri)
        end
        raise "discovery failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        meta = JSON.parse(response.body)
        raise "discovery issuer #{meta['issuer'].inspect} != #{issuer.inspect}" unless meta["issuer"].to_s.chomp("/") == issuer

        ENDPOINTS.each do |k|
          endpoint = URI(meta.fetch(k))
          unless [endpoint.scheme, endpoint.host, endpoint.port] == [uri.scheme, uri.host, uri.port]
            raise "discovery #{k} #{endpoint} is not on #{uri.scheme}://#{uri.host}:#{uri.port}"
          end
        end
        meta
      end
    end
  end
end
