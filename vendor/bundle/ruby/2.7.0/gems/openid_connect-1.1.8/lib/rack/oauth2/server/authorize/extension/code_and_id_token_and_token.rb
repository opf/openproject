module Rack
  module OAuth2
    module Server
      class Authorize
        module Extension
          class CodeAndIdTokenAndToken < Abstract::Handler
            class << self
              def response_type_for?(response_type)
                response_type.split.sort == ['code', 'id_token', 'token']
              end
            end

            def _call(env)
              @request  = Request.new env
              @response = Response.new request
              super
            end

            class Request < Authorize::Extension::CodeAndToken::Request
              def initialize(env)
                super
                @response_type = [:code, :id_token, :token]
                attr_missing!
              end
            end

            class Response < Authorize::Extension::CodeAndToken::Response
              include IdTokenResponse
              attr_required :id_token
            end
          end
        end
      end
    end
  end
end