# frozen_string_literal: true

module Grape
  module ErrorFormatter
    module Txt
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          message = present(message, env)

          result = message.is_a?(Hash) ? ::Grape::Json.dump(message) : message
          rescue_options = options[:rescue_options] || {}
          if rescue_options[:backtrace] && backtrace && !backtrace.empty?
            result += "\r\n backtrace:"
            result += backtrace.join("\r\n ")
          end
          if rescue_options[:original_exception] && original_exception
            result += "\r\n original exception:"
            result += "\r\n #{original_exception.inspect}"
          end
          result
        end
      end
    end
  end
end
