module Rack
  module OAuth2
    class Client
      class Grant
        class AuthorizationCode < Grant
          attr_required :code
          attr_optional :redirect_uri
        end
      end
    end
  end
end