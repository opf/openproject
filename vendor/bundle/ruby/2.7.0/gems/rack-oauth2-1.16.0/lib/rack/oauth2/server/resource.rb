module Rack
  module OAuth2
    module Server
      class Resource < Abstract::Handler
        ACCESS_TOKEN = 'rack.oauth2.access_token'
        DEFAULT_REALM = 'Protected by OAuth 2.0'
        attr_accessor :realm, :request

        def initialize(app, realm = nil, &authenticator)
          @app = app
          @realm = realm
          super(&authenticator)
        end

        def _call(env)
          if request.oauth2?
            access_token = authenticate! request.setup!
            env[ACCESS_TOKEN] = access_token
          end
          @app.call(env)
        rescue Rack::OAuth2::Server::Abstract::Error => e
          e.realm ||= realm
          e.finish
        end

        private

        def authenticate!(request)
          @authenticator.call(request)
        end

        class Request < Rack::Request
          attr_reader :access_token

          def initialize(env)
            @env = env
            @auth_header = Rack::Auth::AbstractRequest.new(env)
          end

          def setup!
            raise 'Define me!'
          end

          def oauth2?
            raise 'Define me!'
          end
        end
      end
    end
  end
end

require 'rack/oauth2/server/resource/error'
require 'rack/oauth2/server/resource/bearer'
require 'rack/oauth2/server/resource/mac'
