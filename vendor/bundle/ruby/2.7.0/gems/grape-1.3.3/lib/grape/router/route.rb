# frozen_string_literal: true

require 'grape/router/pattern'
require 'grape/router/attribute_translator'
require 'forwardable'
require 'pathname'

module Grape
  class Router
    class Route
      ROUTE_ATTRIBUTE_REGEXP = /route_([_a-zA-Z]\w*)/.freeze
      SOURCE_LOCATION_REGEXP = /^(.*?):(\d+?)(?::in `.+?')?$/.freeze
      FIXED_NAMED_CAPTURES = %w[format version].freeze

      attr_accessor :pattern, :translator, :app, :index, :options

      alias attributes translator

      extend Forwardable
      def_delegators :pattern, :path, :origin
      delegate Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES => :attributes

      def method_missing(method_id, *arguments)
        match = ROUTE_ATTRIBUTE_REGEXP.match(method_id.to_s)
        if match
          method_name = match.captures.last.to_sym
          warn_route_methods(method_name, caller(1).shift)
          @options[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_id, _)
        ROUTE_ATTRIBUTE_REGEXP.match?(method_id.to_s)
      end

      def route_method
        warn_route_methods(:method, caller(1).shift, :request_method)
        request_method
      end

      def route_path
        warn_route_methods(:path, caller(1).shift)
        pattern.path
      end

      def initialize(method, pattern, **options)
        method_s = method.to_s
        method_upcase = Grape::Http::Headers.find_supported_method(method_s) || method_s.upcase

        @options    = options.merge(method: method_upcase)
        @pattern    = Pattern.new(pattern, **options)
        @translator = AttributeTranslator.new(**options, request_method: method_upcase)
      end

      def exec(env)
        @app.call(env)
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        translator.respond_to?(:forward_match) && translator.forward_match ? input.start_with?(pattern.origin) : pattern.match?(input)
      end

      def params(input = nil)
        if input.nil?
          pattern.named_captures.keys.each_with_object(translator.params) do |(key), defaults|
            defaults[key] ||= '' unless FIXED_NAMED_CAPTURES.include?(key) || defaults.key?(key)
          end
        else
          parsed = pattern.params(input)
          parsed ? parsed.delete_if { |_, value| value.nil? }.symbolize_keys : {}
        end
      end

      private

      def warn_route_methods(name, location, expected = nil)
        path, line = *location.scan(SOURCE_LOCATION_REGEXP).first
        path = File.realpath(path) if Pathname.new(path).relative?
        expected ||= name
        warn <<-WARNING
#{path}:#{line}: The route_xxx methods such as route_#{name} have been deprecated, please use #{expected}.
        WARNING
      end
    end
  end
end
