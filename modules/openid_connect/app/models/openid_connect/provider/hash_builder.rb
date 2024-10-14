module OpenIDConnect
  module Provider::HashBuilder
    def attribute_map
      OpenIDConnect::Provider::MAPPABLE_ATTRIBUTES
        .index_with { |attr| public_send(:"mapping_#{attr}") }
        .compact_blank
    end

    def to_h # rubocop:disable Metrics/AbcSize
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
        end_session_endpoint:,
        attribute_map:
      }
        .merge(attribute_map)
        .compact_blank

      if oidc_provider == "google"
        h.merge!(
          {
            client_auth_method: :not_basic,
            send_nonce: false, # use state instead of nonce
            state: lambda { SecureRandom.hex(42) }
          }
        )
      end

      h
    end
  end
end
