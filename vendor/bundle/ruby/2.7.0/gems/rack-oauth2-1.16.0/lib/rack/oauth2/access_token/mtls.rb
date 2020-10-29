module Rack
  module OAuth2
    class AccessToken
      class MTLS < Bearer
        attr_required :private_key, :certificate

        def initialize(attributes = {})
          super
          self.token_type = :bearer
          httpclient.ssl_config.client_key = private_key
          httpclient.ssl_config.client_cert = certificate
        end
      end
    end
  end
end
