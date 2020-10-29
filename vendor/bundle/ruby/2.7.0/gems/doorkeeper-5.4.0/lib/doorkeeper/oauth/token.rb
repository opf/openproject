# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class Token
      class << self
        def from_request(request, *methods)
          methods.inject(nil) do |_, method|
            method = self.method(method) if method.is_a?(Symbol)
            credentials = method.call(request)
            break credentials if credentials.present?
          end
        end

        def authenticate(request, *methods)
          if (token = from_request(request, *methods))
            access_token = Doorkeeper.config.access_token_model.by_token(token)
            if access_token.present? && Doorkeeper.config.refresh_token_enabled?
              access_token.revoke_previous_refresh_token!
            end
            access_token
          end
        end

        def from_access_token_param(request)
          request.parameters[:access_token]
        end

        def from_bearer_param(request)
          request.parameters[:bearer_token]
        end

        def from_bearer_authorization(request)
          pattern = /^Bearer /i
          header = request.authorization
          token_from_header(header, pattern) if match?(header, pattern)
        end

        def from_basic_authorization(request)
          pattern = /^Basic /i
          header = request.authorization
          token_from_basic_header(header, pattern) if match?(header, pattern)
        end

        private

        def token_from_basic_header(header, pattern)
          encoded_header = token_from_header(header, pattern)
          decode_basic_credentials_token(encoded_header)
        end

        def decode_basic_credentials_token(encoded_header)
          Base64.decode64(encoded_header).split(/:/, 2).first
        end

        def token_from_header(header, pattern)
          header.gsub(pattern, "")
        end

        def match?(header, pattern)
          header&.match(pattern)
        end
      end
    end
  end
end
