module OpenProject
  module Authentication
    module Strategies
      module Warden
        class JwtOidc < ::Warden::Strategies::Base
          include FailWithHeader

          SUPPORTED_ALG = %w[
            RS256
            RS384
            RS512
          ].freeze

          def valid?
            @access_token = ::Doorkeeper::OAuth::Token.from_bearer_authorization(
              ::Doorkeeper::Grape::AuthorizationDecorator.new(request)
            )
            return false if @access_token.blank?
                
            @unverified_payload, @unverified_header = JWT.decode(@access_token, nil, false)
            @unverified_header.present? && @unverified_payload.present?
          rescue JWT::DecodeError
            false
          end

          def authenticate!
            issuer = @unverified_payload["iss"]
            provider = OpenProject::OpenIDConnect.providers.find { |p| p.configuration[:issuer] == issuer } if issuer.present?
            if provider.present?
              client_id = provider.configuration.fetch(:identifier)
              alg = @unverified_header.fetch("alg")
              key =
                if SUPPORTED_ALG.include?(alg)
                  kid = @unverified_header.fetch("kid")
                  jwks_uri = provider.configuration[:jwks_uri]
                  JSON::JWK::Set::Fetcher.fetch(jwks_uri, kid:).to_key
                else
                  fail_with_header!(error: "invalid_token", error_description: "Token signature algorithm is not supported")
                  return
                end
              begin
                verified_payload, = JWT.decode(
                  @access_token,
                  key,
                  true,
                  {
                    algorithm: alg,
                    verify_iss: true,
                    verify_aud: true,
                    iss: issuer,
                    aud: client_id,
                    required_claims: ["sub", "iss", "aud"]
                  }
                )
              rescue JWT::ExpiredSignature
                fail_with_header!(error: "invalid_token", error_description: "The access token expired")
                return
              rescue JWT::ImmatureSignature
                # happens when nbf time is less than current
                fail_with_header!(error: "invalid_token", error_description: "The access token is used too early")

                return
              rescue JWT::InvalidIssuerError
                fail_with_header!(error: "invalid_token", error_description: "The access token issuer is wrong")
                return
              rescue JWT::InvalidAudError
                fail_with_header!(error: "invalid_token", error_description: "The access token audience claim is wrong")
                return
              end

              user = User.find_by(identity_url: "#{provider.name}:#{verified_payload['sub']}")
              success!(user) if user
            else
              fail_with_header!(error: "invalid_token", error_description: "The access token issuer is unknown")
            end
          end
        end
      end
    end
  end
end
