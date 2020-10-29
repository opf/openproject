module Rack
  module OAuth2
    class AccessToken
      class MAC
        class Signature < Verifier
          attr_required :secret, :ts, :nonce, :method, :request_uri, :host, :port
          attr_optional :ext, :query

          def calculate
            Rack::OAuth2::Util.base64_encode OpenSSL::HMAC.digest(
              hash_generator,
              secret,
              normalized_request_string
            )
          end

          def normalized_request_string
            [
              ts.to_i,
              nonce,
              method.to_s.upcase,
              request_uri,
              host,
              port,
              ext || '',
              nil
            ].join("\n")
          end

        end
      end
    end
  end
end
