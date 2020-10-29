module Rack
  module OAuth2
    module Server
      class Authorize
        class Code < Abstract::Handler
          def _call(env)
            @request  = Request.new env
            @response = Response.new request
            super
          end

          class Request < Authorize::Request
            include Server::Extension::PKCE::AuthorizationRequest

            def initialize(env)
              super
              @response_type = :code
              attr_missing!
            end

            def error_params_location
              :query
            end
          end

          class Response < Authorize::Response
            attr_required :code

            def protocol_params
              super.merge(code: code)
            end

            def protocol_params_location
              :query
            end
          end
        end
      end
    end
  end
end
