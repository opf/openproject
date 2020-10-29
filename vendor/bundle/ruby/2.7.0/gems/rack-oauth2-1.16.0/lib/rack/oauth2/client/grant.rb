module Rack
  module OAuth2
    class Client
      class Grant
        include AttrRequired, AttrOptional

        def initialize(attributes = {})
          (required_attributes + optional_attributes).each do |key|
            self.send "#{key}=", attributes[key]
          end
          attr_missing!
        end

        def grant_type
          self.class.name.demodulize.underscore.to_sym
        end

        def as_json(options = {})
          (required_attributes + optional_attributes).inject({
            grant_type: grant_type
          }) do |hash, key|
            hash.merge! key => self.send(key)
          end
        end
      end
    end
  end
end

require 'rack/oauth2/client/grant/authorization_code'
require 'rack/oauth2/client/grant/password'
require 'rack/oauth2/client/grant/client_credentials'
require 'rack/oauth2/client/grant/refresh_token'
require 'rack/oauth2/client/grant/jwt_bearer'
require 'rack/oauth2/client/grant/saml2_bearer'
require 'rack/oauth2/client/grant/token_exchange'