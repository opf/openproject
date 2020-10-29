module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Response
          include ActiveModel::Validations, AttrRequired, AttrOptional

          cattr_accessor :metadata_attributes
          attr_reader :raw
          attr_accessor :expected_issuer
          uri_attributes = {
            required: [
              :issuer,
              :authorization_endpoint,
              :jwks_uri
            ],
            optional: [
              :token_endpoint,
              :userinfo_endpoint,
              :registration_endpoint,
              :end_session_endpoint,
              :service_documentation,
              :check_session_iframe,
              :op_policy_uri,
              :op_tos_uri
            ]
          }
          attr_required(*(uri_attributes[:required] + [
            :response_types_supported,
            :subject_types_supported,
            :id_token_signing_alg_values_supported
          ]))
          attr_optional(*(uri_attributes[:optional] + [
            :scopes_supported,
            :response_modes_supported,
            :grant_types_supported,
            :acr_values_supported,
            :id_token_encryption_alg_values_supported,
            :id_token_encryption_enc_values_supported,
            :userinfo_signing_alg_values_supported,
            :userinfo_encryption_alg_values_supported,
            :userinfo_encryption_enc_values_supported,
            :request_object_signing_alg_values_supported,
            :request_object_encryption_alg_values_supported,
            :request_object_encryption_enc_values_supported,
            :token_endpoint_auth_methods_supported,
            :token_endpoint_auth_signing_alg_values_supported,
            :display_values_supported,
            :claim_types_supported,
            :claims_supported,
            :claims_locales_supported,
            :ui_locales_supported,
            :claims_parameter_supported,
            :request_parameter_supported,
            :request_uri_parameter_supported,
            :require_request_uri_registration
          ]))

          validates(*required_attributes, presence: true)
          validates(*uri_attributes.values.flatten, url: true, allow_nil: true)
          validates :issuer, with: :validate_issuer_matching

          def initialize(hash)
            (required_attributes + optional_attributes).each do |key|
              self.send "#{key}=", hash[key]
            end
            @raw = hash
          end

          def as_json(options = {})
            validate!
            (required_attributes + optional_attributes).inject({}) do |hash, _attr_|
              value = self.send _attr_
              hash.merge! _attr_ => value unless value.nil?
              hash
            end
          end

          def validate!
            valid? or raise ValidationFailed.new(self)
          end

          def jwks
            @jwks ||= JSON.parse(
              OpenIDConnect.http_client.get_content(jwks_uri)
            ).with_indifferent_access
            JSON::JWK::Set.new @jwks[:keys]
          end

          def public_keys
            @public_keys ||= jwks.collect(&:to_key)
          end

          private

          def validate_issuer_matching
            if expected_issuer.present? && issuer != expected_issuer
              if OpenIDConnect.validate_discovery_issuer
                errors.add :issuer, 'mismatch'
              else
                OpenIDConnect.logger.warn 'ignoring issuer mismach.'
              end
            end
          end
        end
      end
    end
  end
end
