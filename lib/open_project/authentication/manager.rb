module OpenProject
  module Authentication
    class Manager < Warden::Manager
      def self.strategies
        @strategies ||= begin
          hash = {
            api_v3: [:global_basic_auth, :user_basic_auth, :session]
          }

          hash.tap do |h|
            h.default = []
          end
        end
      end

      def self.register_strategy(name, clazz, scopes)
        Warden::Strategies.add name, clazz

        scopes.each do |scope|
          strategies[scope] << name
        end
      end

      def self.configure(config)
        config.default_strategies :session
        config.failure_app = OpenProject::Authentication::FailureApp

        config.scope_defaults :api_v3, strategies: strategies[:api_v3], store: false
      end

      def initialize(app, options={}, &configure)
        block = lambda do |config|
          self.class.configure config

          configure.call config if configure
        end

        super app, options, &block
      end
    end
  end
end
