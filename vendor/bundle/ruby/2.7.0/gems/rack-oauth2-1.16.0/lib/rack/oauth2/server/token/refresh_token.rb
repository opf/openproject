module Rack
  module OAuth2
    module Server
      class Token
        class RefreshToken < Abstract::Handler
          def _call(env)
            @request  = Request.new(env)
            @response = Response.new(request)
            super
          end

          class Request < Token::Request
            attr_required :refresh_token

            def initialize(env)
              super
              @grant_type    = :refresh_token
              @refresh_token = params['refresh_token']
              attr_missing!
            end
          end
        end
      end
    end
  end
end