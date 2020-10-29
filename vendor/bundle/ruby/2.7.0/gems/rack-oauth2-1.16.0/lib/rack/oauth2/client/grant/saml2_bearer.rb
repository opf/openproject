module Rack
  module OAuth2
    class Client
      class Grant
        class SAML2Bearer < Grant
          attr_required :assertion

          def grant_type
            URN::GrantType::SAML2_BEARER
          end
        end
      end
    end
  end
end