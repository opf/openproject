module Rack
  module OAuth2
    module Server
      class Token
        class ClientCredentials < Abstract::Handler
          def _call(env)
            @request  = Request.new(env)
            @response = Response.new(request)
            super
          end

          class Request < Token::Request
            def initialize(env)
              super
              @grant_type = :client_credentials
              attr_missing!
            end
          end
        end
      end
    end
  end
end