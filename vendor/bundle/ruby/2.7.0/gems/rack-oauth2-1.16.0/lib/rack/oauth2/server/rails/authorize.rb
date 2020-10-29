module Rack
  module OAuth2
    module Server
      module Rails
        class Authorize < Server::Authorize
          def initialize(app)
            super()
            @app = app
          end

          def _call(env)
            prepare_oauth_env env
            @app.call env
          rescue Rack::OAuth2::Server::Abstract::Error => e
            e.finish
          end

          private

          def prepare_oauth_env(env)
            response_type = response_type_for(
              Server::Authorize::Request.new(env)
            ).new
            response_type._call(env)
            response_type.response.extend ResponseExt
            env[REQUEST]  = response_type.request
            env[RESPONSE] = response_type.response
          rescue Rack::OAuth2::Server::Abstract::Error => e
            env[ERROR] = e
          end

          module ResponseExt
            include Rails::ResponseExt

            def approve!
              super
              finish
            end
          end
        end
      end
    end
  end
end
