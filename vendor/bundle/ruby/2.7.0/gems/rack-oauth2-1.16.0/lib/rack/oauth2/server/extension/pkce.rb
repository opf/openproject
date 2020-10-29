module Rack
  module OAuth2
    module Server
      module Extension
        module PKCE
          module AuthorizationRequest
            def self.included(klass)
              klass.send :attr_optional, :code_challenge, :code_challenge_method
            end

            def initialize(env)
              super
              @code_challenge = params['code_challenge']
              @code_challenge_method = params['code_challenge_method']
            end
          end

          module TokenRequest
            def self.included(klass)
              klass.send :attr_optional, :code_verifier
            end

            def initialize(env)
              super
              @code_verifier = params['code_verifier']
            end

            def verify_code_verifier!(code_challenge, code_challenge_method = :S256)
              if code_verifier.present? || code_challenge.present?
                case code_challenge_method.try(:to_sym)
                when :S256
                  code_challenge == Util.urlsafe_base64_encode(
                    OpenSSL::Digest::SHA256.digest(code_verifier.to_s)
                  ) or invalid_grant!
                when :plain
                  code_challenge == code_verifier or invalid_grant!
                else
                  invalid_grant!
                end
              end
            end
          end
        end
      end
    end
  end
end