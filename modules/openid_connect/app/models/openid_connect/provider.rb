module OpenIDConnect
  class Provider < AuthProvider
    OIDC_PROVIDERS = ["google", "microsoft_entra", "custom"].freeze
    DISCOVERABLE_ATTRIBUTES_ALL = %i[authorization_endpoint
                                     userinfo_endpoint
                                     token_endpoint
                                     end_session_endpoint
                                     jwks_uri
                                     issuer].freeze
    DISCOVERABLE_ATTRIBUTES_OPTIONAL = %i[end_session_endpoint].freeze
    DISCOVERABLE_ATTRIBUTES_MANDATORY = DISCOVERABLE_ATTRIBUTES_ALL - %i[end_session_endpoint]

    store_attribute :options, :oidc_provider, :string
    store_attribute :options, :metadata_url, :string
    DISCOVERABLE_ATTRIBUTES_ALL.each do |attribute|
      store_attribute :options, attribute, :string
    end
    store_attribute :options, :client_id, :string
    store_attribute :options, :client_secret, :string
    store_attribute :options, :tenant, :string

    def self.slug_fragment = "oidc"

    def seeded_from_env?
      (Setting.seed_openid_connect_provider || {}).key?(slug)
    end

    def basic_details_configured?
      display_name.present? && (oidc_provider == "microsoft_entra" ? tenant.present? : true)
    end

    def advanced_details_configured?
      client_id.present? && client_secret.present?
    end

    def metadata_configured?
      DISCOVERABLE_ATTRIBUTES_MANDATORY.all? do |mandatory_attribute|
        public_send(mandatory_attribute).present?
      end
    end

    def configured?
      basic_details_configured? && advanced_details_configured? && metadata_configured?
    end

    def to_h
      h = {
        name: slug,
        icon:,
        display_name:,
        userinfo_endpoint:,
        authorization_endpoint:,
        jwks_uri:,
        host: URI(issuer).host,
        issuer:,
        identifier: client_id,
        secret: client_secret,
        token_endpoint:,
        limit_self_registration:,
        end_session_endpoint:
      }.to_h

      if oidc_provider == "google"
        h.merge!({
                   client_auth_method: :not_basic,
                   send_nonce: false, # use state instead of nonce
                   state: lambda { SecureRandom.hex(42) }
                 })
      end
      h
    end

    def icon
      case oidc_provider
      when "google"
        "openid_connect/auth_provider-google.png"
      when "microsoft_entra"
        "openid_connect/auth_provider-azure.png"
      else
        "openid_connect/auth_provider-custom.png"
      end
    end
  end
end
