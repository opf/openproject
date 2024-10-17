module OpenIDConnect
  module Provider::HashBuilder
    def attribute_map
      OpenIDConnect::Provider::MAPPABLE_ATTRIBUTES
        .index_with { |attr| public_send(:"mapping_#{attr}") }
        .compact_blank
    end

    def to_h # rubocop:disable Metrics/AbcSize
      {
        name: slug,
        oidc_provider:,
        icon:,
        host:,
        scheme:,
        port:,
        display_name:,
        userinfo_endpoint:,
        authorization_endpoint:,
        jwks_uri:,
        issuer:,
        identifier: client_id,
        secret: client_secret,
        token_endpoint:,
        limit_self_registration:,
        end_session_endpoint:,
        attribute_map:
      }.merge(attribute_map)
       .merge(provider_specific_to_h)
       .compact_blank
    end

    def provider_specific_to_h
      case oidc_provider
      when "google"
        {
          client_auth_method: :not_basic,
          send_nonce: false
        }
      when "microsoft_entra"
        {
          use_graph_api:
        }
      else
        {}
      end
    end
  end
end
