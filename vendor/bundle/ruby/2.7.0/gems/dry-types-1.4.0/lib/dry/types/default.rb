# frozen_string_literal: true

require 'dry/types/decorator'

module Dry
  module Types
    # Default types are useful when a missing value should be replaced by a default one
    #
    # @api public
    class Default
      # @api private
      class Callable < Default
        include Dry::Equalizer(:type, inspect: false, immutable: true)

        # Evaluates given callable
        # @return [Object]
        def evaluate
          value.call(type)
        end
      end

      include Type
      include Decorator
      include Builder
      include Printable
      include Dry::Equalizer(:type, :value, inspect: false, immutable: true)

      # @return [Object]
      attr_reader :value

      alias_method :evaluate, :value

      # @param [Object, #call] value
      #
      # @return [Class] {Default} or {Default::Callable}
      #
      # @api private
      def self.[](value)
        if value.respond_to?(:call)
          Callable
        else
          self
        end
      end

      # @param [Type] type
      # @param [Object] value
      #
      # @api private
      def initialize(type, value, **options)
        super
        @value = value
      end

      # Build a constrained type
      #
      # @param [Array] args see {Dry::Types::Builder#constrained}
      #
      # @return [Default]
      #
      # @api public
      def constrained(*args)
        type.constrained(*args).default(value)
      end

      # @return [true]
      #
      # @api public
      def default?
        true
      end

      # @param [Object] input
      #
      # @return [Result::Success]
      #
      # @api public
      def try(input)
        success(call(input))
      end

      # @return [Boolean]
      #
      # @api public
      def valid?(value = Undefined)
        Undefined.equal?(value) || super
      end

      # @param [Object] input
      #
      # @return [Object] value passed through {#type} or {#default} value
      #
      # @api private
      def call_unsafe(input = Undefined)
        if input.equal?(Undefined)
          evaluate
        else
          Undefined.default(type.call_unsafe(input)) { evaluate }
        end
      end

      # @param [Object] input
      #
      # @return [Object] value passed through {#type} or {#default} value
      #
      # @api private
      def call_safe(input = Undefined, &block)
        if input.equal?(Undefined)
          evaluate
        else
          Undefined.default(type.call_safe(input, &block)) { evaluate }
        end
      end
    end
  end
end
