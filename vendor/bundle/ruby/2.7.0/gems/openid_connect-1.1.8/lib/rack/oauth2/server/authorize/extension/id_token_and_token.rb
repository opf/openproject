module Rack
  module OAuth2
    module Server
      class Authorize
        module Extension
          class IdTokenAndToken < Abstract::Handler
            class << self
              def response_type_for?(response_type)
                response_type.split.sort == ['id_token', 'token']
              end
            end

            def _call(env)
              @request  = Request.new env
              @response = Response.new request
              super
            end

            class Request < Authorize::Token::Request
              def initialize(env)
                super
                @response_type = [:id_token, :token]
                attr_missing!
              end
            end

            class Response < Authorize::Token::Response
              include IdTokenResponse
              attr_required :id_token
            end
          end
        end
      end
    end
  end
end