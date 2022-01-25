module OpenProject
  module Logging
    class SentryLogger
      class << self
        ##
        # Capture a message to sentry
        def log(message, log_context = {})
          Sentry.configure_scope do |sentry_scope|
            build_sentry_context(sentry_scope, log_context.to_h)

            if log_context[:exception]
              Sentry.capture_exception(log_context[:exception])
            else
              Sentry.capture_message(message, level: sentry_level(log_context[:level]))
            end
          end
        end

        ##
        # Whether sentry logging is enabled?
        def enabled?
          sentry_dsn.present?
        end

        ##
        # Sentry logging DSN
        def sentry_dsn
          @sentry_dsn ||= OpenProject::Configuration.sentry_dsn.presence || ENV["SENTRY_DSN"].presence
        end

        private

        ##
        # Build the sentry warning level from context
        #
        # Sentry uses "warning" as the warn level
        # and is consistent with rails otherwise
        def sentry_level(level)
          return 'warning' if level.to_s == 'warn'

          level
        end

        ##
        # Build the sentry context from the openproject logging context
        def build_sentry_context(sentry_scope, log_context)
          if (user = log_context[:current_user])
            sentry_scope.set_user id: user.id, email: user.mail, username: user.login.presence || 'unknown'
            sentry_scope.set_tags 'user.locale': user.language.presence || Setting.default_language
          end

          if (params = log_context[:params])
            sentry_scope.set_context 'params', filter_params(params)
          end

          if (rack_env = log_context[:request]&.env)
            sentry_scope.set_rack_env(rack_env)
          end

          if (ref = log_context[:reference])
            sentry_scope.set_fingerprint [ref]
          end

          sentry_scope.set_tags code_origin: 'backend'

          # Collect extra information from payload extender
          # e.g., with saas tenant information
          extra = ::OpenProject::Logging.extend_payload! log_context[:extra] || {}, { sentry_scope: sentry_scope }
          sentry_scope.set_extras extra
        end

        def filter_params(params)
          f = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
          res = f.filter(params)

          # make sure to return plain hash rather than ActionController::Parameters
          res.respond_to?(:to_unsafe_h) ? res.to_unsafe_h : res.to_h
        rescue StandardError => e
          { filter_failed: e.message }
        end
      end
    end
  end
end
