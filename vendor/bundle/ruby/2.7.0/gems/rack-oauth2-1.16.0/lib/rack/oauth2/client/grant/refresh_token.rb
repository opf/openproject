module Rack
  module OAuth2
    class Client
      class Grant
        class RefreshToken < Grant
          attr_required :refresh_token
        end
      end
    end
  end
end