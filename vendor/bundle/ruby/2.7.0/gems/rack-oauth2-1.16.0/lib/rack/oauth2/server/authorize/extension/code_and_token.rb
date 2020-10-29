module Rack
  module OAuth2
    module Server
      class Authorize
        module Extension
          class CodeAndToken < Abstract::Handler
            class << self
              def response_type_for?(response_type)
                response_type.split.sort == ['code', 'token']
              end
            end

            def _call(env)
              @request  = Request.new env
              @response = Response.new request
              super
            end

            class Request < Authorize::Token::Request
              include Server::Extension::PKCE::AuthorizationRequest

              def initialize(env)
                super
                @response_type = [:code, :token]
                attr_missing!
              end
            end

            class Response < Authorize::Token::Response
              attr_required :code

              def protocol_params
                super.merge(code: code)
              end
            end
          end
        end
      end
    end
  end
end
