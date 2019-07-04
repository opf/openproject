module OpenProject
  module Logging
    class LogDelegator
      class << self

        ##
        # Consume a message and let it be handled
        # by all handlers
        def log(exception, context = {})
          message =
            if exception.is_a? Exception
              context[:exception] = exception
              "#{exception}: #{exception.message}"
            else
              exception.to_s
            end

          # Mark backtrace
          if context[:exception]
            context[:backtrace] = clean_backtrace(context[:exception])
          end

          # Set current contexts
          context[:level] ||= context[:exception] ? :error : :info
          context[:current_user] ||= User.current

          registered_handlers.values.each do |handler|
            handler.call message, context
          rescue StandardError => e
            Rails.logger.error "Failed to delegate log to #{handler.inspect}: #{e.inspect}"
          end

          nil
        rescue StandardError => e
          Rails.logger.error "Failed to process log message #{exception.inspect}: #{e.inspect}"
        end

        %i(debug info warn error fatal unknown).each do |level|
          define_method(level) do |*args|
            message = args.shift
            context = args.shift || {}

            log(message, context.merge(level: level))
          end
        end

        ##
        # Get a clean backtrace
        def clean_backtrace(exception)
          return nil unless exception&.backtrace

          Rails.backtrace_cleaner.clean exception.backtrace, :full
        end

        ##
        # The active set of error handlers
        def registered_handlers
          @handlers ||= default_handlers
        end

        ##
        # Register a new handler
        def register(key, handler)
          raise "#{key} already registered" if registered_handlers.key?(key)
          raise "handler must respond_to #call" unless handler.respond_to?(:call)

          @handlers[key] = handler
        end

        ##
        # Create a payload for lograge from a controller request line
        def controller_payload_hash(controller)
          {
            user: User.current.try(:id)
          }
        end

        private

        def default_handlers
          { rails_logger: method(:rails_logger_handler) }
        end

        ##
        # A lambda handler for logging the error
        # to rails.
        def rails_logger_handler(message, context = {})
          Rails.logger.public_send(
            context[:level],
            "#{context_string(context)} #{message}"
          )
        end

        ##
        # Create a context string
        def context_string(context)
          %i[current_user project reference]
            .map do |key|
              value = context[key]

              if value
                "[#{key}=#{value}]"
              end
            end
            .compact
            .join(' ')
        end
      end
    end
  end
end
