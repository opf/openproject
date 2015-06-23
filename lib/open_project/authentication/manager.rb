require 'set'

module OpenProject
  module Authentication
    class Manager < Warden::Manager
      serialize_into_session do |user|
        user.id
      end

      serialize_from_session do |id|
        User.find id
      end

      def initialize(app, options = {}, &configure)
        block = lambda do |config|
          self.class.configure_warden config

          configure.call config if configure
        end

        super app, options, &block
      end

      class << self
        def config
          @config ||= Hash.new
        end

        def scope_config(scope)
          config[scope] ||= ScopeSettings.new false
        end

        def failure_handlers
          @failure_handlers ||= {}
        end

        def auth_scheme(name)
          auth_schemes[name] ||= AuthSchemeInfo.new Set.new
        end

        def auth_schemes
          @auth_schemes ||= {}
        end

        def configure_warden(warden_config)
          warden_config.default_strategies :session
          warden_config.failure_app = OpenProject::Authentication::FailureApp.new failure_handlers

          config.each do |scope, cfg|
            warden_config.scope_defaults scope, strategies: cfg.strategies, store: cfg.store
          end
        end
      end

      class ScopeSettings < Struct.new(:store, :strategies, :realm)
      end

      class AuthSchemeInfo < Struct.new(:strategies)
      end
    end
  end
end
