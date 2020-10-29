module Airbrake
  class Config
    # Validator validates values of {Airbrake::Config} options. A valid config
    # is a config that guarantees that data can be sent to Airbrake given its
    # configuration.
    #
    # @api private
    # @since v1.5.0
    class Validator
      # @return [Array<Class>] the list of allowed types to configure the
      #   environment option
      VALID_ENV_TYPES = [NilClass, String, Symbol].freeze

      class << self
        # @param [Airbrake::Config] config
        # @since v4.1.0
        def validate(config)
          promise = Airbrake::Promise.new

          unless valid_project_id?(config)
            return promise.reject(':project_id is required')
          end

          unless valid_project_key?(config)
            return promise.reject(':project_key is required')
          end

          unless valid_environment?(config)
            return promise.reject(
              "the 'environment' option must be configured " \
              "with a Symbol (or String), but '#{config.environment.class}' was " \
              "provided: #{config.environment}",
            )
          end

          promise.resolve(:ok)
        end

        # Whether the given +config+ allows sending data to Airbrake. It doesn't
        # matter if it's valid or invalid.
        #
        # @param [Airbrake::Config] config
        # @since v4.1.0
        def check_notify_ability(config)
          promise = Airbrake::Promise.new

          unless config.error_notifications
            return promise.reject('error notifications are disabled')
          end

          if ignored_environment?(config)
            return promise.reject(
              "current environment '#{config.environment}' is ignored",
            )
          end

          promise.resolve(:ok)
        end

        private

        def valid_project_id?(config)
          return true if config.project_id.to_i > 0

          false
        end

        def valid_project_key?(config)
          return false unless config.project_key.is_a?(String)
          return false if config.project_key.empty?

          true
        end

        def valid_environment?(config)
          VALID_ENV_TYPES.any? { |type| config.environment.is_a?(type) }
        end

        def ignored_environment?(config)
          if config.ignore_environments.any? && config.environment.nil?
            config.logger.warn(
              "#{LOG_LABEL} the 'environment' option is not set, " \
              "'ignore_environments' has no effect",
            )
          end

          return false if config.ignore_environments.none? || !config.environment

          env = config.environment.to_s
          config.ignore_environments.any? do |pattern|
            pattern.is_a?(Regexp) ? env.match(pattern) : env == pattern.to_s
          end
        end
      end
    end
  end
end
