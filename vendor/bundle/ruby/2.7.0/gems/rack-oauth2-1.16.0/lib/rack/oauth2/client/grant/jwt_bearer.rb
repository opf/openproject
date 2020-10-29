module Rack
  module OAuth2
    class Client
      class Grant
        class JWTBearer < Grant
          attr_required :assertion

          def grant_type
            URN::GrantType::JWT_BEARER
          end
        end
      end
    end
  end
end