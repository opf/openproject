# frozen_string_literal: true

require 'grape/middleware/base'
require 'active_support/core_ext/string/output_safety'

module Grape
  module Middleware
    class Error < Base
      def default_options
        {
          default_status: 500, # default status returned on error
          default_message: '',
          format: :txt,
          helpers: nil,
          formatters: {},
          error_formatters: {},
          rescue_all: false, # true to rescue all exceptions
          rescue_grape_exceptions: false,
          rescue_subclasses: true, # rescue subclasses of exceptions listed
          rescue_options: {
            backtrace: false, # true to display backtrace, true to let Grape handle Grape::Exceptions
            original_exception: false, # true to display exception
          },
          rescue_handlers: {}, # rescue handler blocks
          base_only_rescue_handlers: {}, # rescue handler blocks rescuing only the base class
          all_rescue_handler: nil, # rescue handler block to rescue from all exceptions
        }
      end

      def initialize(app, **options)
        super
        self.class.send(:include, @options[:helpers]) if @options[:helpers]
      end

      def call!(env)
        @env = env
        begin
          error_response(catch(:error) do
            return @app.call(@env)
          end)
        rescue Exception => error # rubocop:disable Lint/RescueException
          handler =
            rescue_handler_for_base_only_class(error.class) ||
            rescue_handler_for_class_or_its_ancestor(error.class) ||
            rescue_handler_for_grape_exception(error.class) ||
            rescue_handler_for_any_class(error.class) ||
            raise

          run_rescue_handler(handler, error)
        end
      end

      def error!(message, status = options[:default_status], headers = {}, backtrace = [], original_exception = nil)
        headers = headers.reverse_merge(Grape::Http::Headers::CONTENT_TYPE => content_type)
        rack_response(format_message(message, backtrace, original_exception), status, headers)
      end

      def default_rescue_handler(e)
        error_response(message: e.message, backtrace: e.backtrace, original_exception: e)
      end

      # TODO: This method is deprecated. Refactor out.
      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = { Grape::Http::Headers::CONTENT_TYPE => content_type }
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || error[:original_exception] && error[:original_exception].backtrace || []
        original_exception = error.is_a?(Exception) ? error : error[:original_exception] || nil
        rack_response(format_message(message, backtrace, original_exception), status, headers)
      end

      def rack_response(message, status = options[:default_status], headers = { Grape::Http::Headers::CONTENT_TYPE => content_type })
        if headers[Grape::Http::Headers::CONTENT_TYPE] == TEXT_HTML
          message = ERB::Util.html_escape(message)
        end
        Rack::Response.new([message], status, headers)
      end

      def format_message(message, backtrace, original_exception = nil)
        format = env[Grape::Env::API_FORMAT] || options[:format]
        formatter = Grape::ErrorFormatter.formatter_for(format, **options)
        throw :error,
              status: 406,
              message: "The requested format '#{format}' is not supported.",
              backtrace: backtrace,
              original_exception: original_exception unless formatter
        formatter.call(message, backtrace, options, env, original_exception)
      end

      private

      def rescue_handler_for_base_only_class(klass)
        error, handler = options[:base_only_rescue_handlers].find { |err, _handler| klass == err }

        return unless error

        handler || :default_rescue_handler
      end

      def rescue_handler_for_class_or_its_ancestor(klass)
        error, handler = options[:rescue_handlers].find { |err, _handler| klass <= err }

        return unless error

        handler || :default_rescue_handler
      end

      def rescue_handler_for_grape_exception(klass)
        return unless klass <= Grape::Exceptions::Base
        return :error_response if klass == Grape::Exceptions::InvalidVersionHeader
        return unless options[:rescue_grape_exceptions] || !options[:rescue_all]

        :error_response
      end

      def rescue_handler_for_any_class(klass)
        return unless klass <= StandardError
        return unless options[:rescue_all] || options[:rescue_grape_exceptions]

        options[:all_rescue_handler] || :default_rescue_handler
      end

      def run_rescue_handler(handler, error)
        if handler.instance_of?(Symbol)
          raise NoMethodError, "undefined method `#{handler}'" unless respond_to?(handler)

          handler = public_method(handler)
        end

        response = handler.arity.zero? ? instance_exec(&handler) : instance_exec(error, &handler)

        if response.is_a?(Rack::Response)
          response
        else
          run_rescue_handler(:default_rescue_handler, Grape::Exceptions::InvalidResponse.new)
        end
      end
    end
  end
end
