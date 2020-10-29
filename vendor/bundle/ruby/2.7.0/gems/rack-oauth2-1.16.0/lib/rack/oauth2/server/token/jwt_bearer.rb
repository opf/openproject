module Rack
  module OAuth2
    module Server
      class Token
        class JWTBearer < Abstract::Handler
          def _call(env)
            @request  = Request.new env
            @response = Response.new request
            super
          end

          class Request < Token::Request
            attr_required :assertion
            attr_optional :client_id

            def initialize(env)
              super
              @grant_type = URN::GrantType::JWT_BEARER
              @assertion = params['assertion']
              attr_missing!
            end
          end
        end
      end
    end
  end
end