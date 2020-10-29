# frozen_string_literal: true

module Grape
  module ErrorFormatter
    module Json
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          result = wrap_message(present(message, env))

          rescue_options = options[:rescue_options] || {}
          if rescue_options[:backtrace] && backtrace && !backtrace.empty?
            result = result.merge(backtrace: backtrace)
          end
          if rescue_options[:original_exception] && original_exception
            result = result.merge(original_exception: original_exception.inspect)
          end
          ::Grape::Json.dump(result)
        end

        private

        def wrap_message(message)
          if message.is_a?(Exceptions::ValidationErrors) || message.is_a?(Hash)
            message
          else
            { error: message }
          end
        end
      end
    end
  end
end
