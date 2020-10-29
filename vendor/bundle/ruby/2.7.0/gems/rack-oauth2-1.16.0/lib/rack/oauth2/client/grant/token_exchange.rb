module Rack
  module OAuth2
    class Client
      class Grant
        class TokenExchange < Grant
          attr_required :subject_token, :subject_token_type

          def grant_type
            URN::GrantType::TOKEN_EXCHANGE
          end
        end
      end
    end
  end
end