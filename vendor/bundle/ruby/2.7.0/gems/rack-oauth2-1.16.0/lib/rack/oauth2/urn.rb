module Rack
  module OAuth2
    module URN
      module TokenType
        JWT           = 'urn:ietf:params:oauth:token-type:jwt'           # RFC7519
        ACCESS_TOKEN  = 'urn:ietf:params:oauth:token-type:access_token'  # RFC8693
        REFRESH_TOKEN = 'urn:ietf:params:oauth:token-type:refresh_token' # RFC8693
      end

      module GrantType
        JWT_BEARER     = 'urn:ietf:params:oauth:grant-type:jwt-bearer'     # RFC7523
        SAML2_BEARER   = 'urn:ietf:params:oauth:grant-type:saml2-bearer'   # RFC7522
        TOKEN_EXCHANGE = 'urn:ietf:params:oauth:grant-type:token-exchange' # RFC8693
      end

      module ClientAssertionType
        JWT_BEARER   = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'   # RFC7523
        SAML2_BEARER = 'urn:ietf:params:oauth:client-assertion-type:saml2-bearer' # RFC7522
      end
    end
  end
end