module Rack
  module OAuth2
    module Server
      class Authorize
        class Token < Abstract::Handler
          def _call(env)
            @request  = Request.new env
            @response = Response.new request
            super
          end

          class Request < Authorize::Request
            def initialize(env)
              super
              @response_type = :token
              attr_missing!
            end

            def error_params_location
              :fragment
            end
          end

          class Response < Authorize::Response
            attr_required :access_token

            def protocol_params
              super.merge(
                access_token.token_response.delete_if do |k, v|
                  k == :refresh_token
                end
              )
            end

            def protocol_params_location
              :fragment
            end
          end
        end
      end
    end
  end
end