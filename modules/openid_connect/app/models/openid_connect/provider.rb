module OpenIDConnect
  class Provider < AuthProvider
    include HashBuilder

    OIDC_PROVIDERS = %w[google microsoft_entra custom].freeze
    DISCOVERABLE_ATTRIBUTES_ALL = %i[authorization_endpoint
                                     userinfo_endpoint
                                     token_endpoint
                                     end_session_endpoint
                                     jwks_uri
                                     issuer].freeze
    DISCOVERABLE_ATTRIBUTES_OPTIONAL = %i[end_session_endpoint].freeze
    DISCOVERABLE_ATTRIBUTES_MANDATORY = DISCOVERABLE_ATTRIBUTES_ALL - %i[end_session_endpoint jwks_uri]

    MAPPABLE_ATTRIBUTES = %i[login email first_name last_name].freeze

    store_attribute :options, :oidc_provider, :string
    store_attribute :options, :metadata_url, :string
    store_attribute :options, :icon, :string

    DISCOVERABLE_ATTRIBUTES_ALL.each do |attribute|
      store_attribute :options, attribute, :string
    end
    MAPPABLE_ATTRIBUTES.each do |attribute|
      store_attribute :options, "mapping_#{attribute}", :string
    end

    store_attribute :options, :client_id, :string
    store_attribute :options, :client_secret, :string
    store_attribute :options, :tenant, :string

    def self.slug_fragment = "oidc"

    def seeded_from_env?
      (Setting.seed_oidc_provider || {}).key?(slug)
    end

    def basic_details_configured?
      display_name.present? && (oidc_provider == "microsoft_entra" ? tenant.present? : true)
    end

    def advanced_details_configured?
      client_id.present? && client_secret.present?
    end

    def metadata_configured?
      return false unless metadata_url.present?

      DISCOVERABLE_ATTRIBUTES_MANDATORY.all? do |mandatory_attribute|
        public_send(mandatory_attribute).present?
      end
    end

    def mapping_configured?
      MAPPABLE_ATTRIBUTES.any? do |mandatory_attribute|
        public_send(:"mapping_#{mandatory_attribute}").present?
      end
    end

    def configured?
      basic_details_configured? && advanced_details_configured? && metadata_configured?
    end

    def icon
      case oidc_provider
      when "google"
        "openid_connect/auth_provider-google.png"
      when "microsoft_entra"
        "openid_connect/auth_provider-azure.png"
      else
        super.presence || "openid_connect/auth_provider-custom.png"
      end
    end
  end
end
