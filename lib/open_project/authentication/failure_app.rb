module OpenProject
  module Authentication
    class FailureApp
      attr_reader :failure_handlers

      def initialize(failure_handlers)
        @failure_handlers = failure_handlers
      end

      def call(env)
        warden = self.warden env
        scope = self.scope env

        if warden && warden.result == :failure
          handler = failure_handlers[scope] || default_failure_handler

          if handler
            handler.call warden, warden_options(env)
          else
            handle_failure warden
          end
        else
          unauthorized
        end
      end

      def default_failure_handler
        failure_handlers[nil]
      end

      def handle_failure(warden)
        [warden.status || 401, warden.headers, [warden.message]]
      end

      def unauthorized
        [401, {}, ['unauthorized']]
      end

      def warden(env)
        env['warden']
      end

      def warden_options(env)
        Hash(env['warden.options'])
      end

      def scope(env)
        warden_options(env)[:scope]
      end
    end
  end
end
