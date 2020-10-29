module Rack::OAuth2::Server
  module IdTokenResponse
    def self.prepended(klass)
      klass.send :attr_optional, :id_token
    end

    def protocol_params_location
      :fragment
    end

    def protocol_params
      super.merge(
        id_token: id_token
      )
    end
  end
  Token::Response.send :prepend, IdTokenResponse
end

require 'rack/oauth2/server/authorize/extension/code_and_id_token'
require 'rack/oauth2/server/authorize/extension/code_and_token'
require 'rack/oauth2/server/authorize/extension/code_and_id_token_and_token'
require 'rack/oauth2/server/authorize/extension/id_token'
require 'rack/oauth2/server/authorize/extension/id_token_and_token'