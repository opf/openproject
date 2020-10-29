module Rack
  module OAuth2
    module Server
      class Token
        class Password < Abstract::Handler
          def _call(env)
            @request  = Request.new(env)
            @response = Response.new(request)
            super
          end

          class Request < Token::Request
            attr_required :username, :password

            def initialize(env)
              super
              @grant_type = :password
              @username   = params['username']
              @password   = params['password']
              attr_missing!
            end
          end
        end
      end
    end
  end
end