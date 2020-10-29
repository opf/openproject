# frozen_string_literal: true

require 'dry/types/decorator'
require 'dry/types/constraints'
require 'dry/types/constrained/coercible'

module Dry
  module Types
    # Constrained types apply rules to the input
    #
    # @api public
    class Constrained
      include Type
      include Decorator
      include Builder
      include Printable
      include Dry::Equalizer(:type, :rule, inspect: false, immutable: true)

      # @return [Dry::Logic::Rule]
      attr_reader :rule

      # @param [Type] type
      #
      # @param [Hash] options
      #
      # @api public
      def initialize(type, **options)
        super
        @rule = options.fetch(:rule)
      end

      # @api private
      #
      # @return [Object]
      #
      # @api public
      def call_unsafe(input)
        result = rule.(input)

        if result.success?
          type.call_unsafe(input)
        else
          raise ConstraintError.new(result, input)
        end
      end

      # @api private
      #
      # @return [Object]
      #
      # @api public
      def call_safe(input, &block)
        if rule[input]
          type.call_safe(input, &block)
        else
          yield
        end
      end

      # Safe coercion attempt. It is similar to #call with a
      # block given but returns a Result instance with metadata
      # about errors (if any).
      #
      # @overload try(input)
      #   @param [Object] input
      #   @return [Logic::Result]
      #
      # @overload try(input)
      #   @param [Object] input
      #   @yieldparam [Failure] failure
      #   @yieldreturn [Object]
      #   @return [Object]
      #
      # @api public
      def try(input, &block)
        result = rule.(input)

        if result.success?
          type.try(input, &block)
        else
          failure = failure(input, ConstraintError.new(result, input))
          block_given? ? yield(failure) : failure
        end
      end

      # @param [Hash] options
      #   The options hash provided to {Types.Rule} and combined
      #   using {&} with previous {#rule}
      #
      # @return [Constrained]
      #
      # @see Dry::Logic::Operators#and
      #
      # @api public
      def constrained(options)
        with(rule: rule & Types.Rule(options))
      end

      # @return [true]
      #
      # @api public
      def constrained?
        true
      end

      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api public
      def ===(value)
        valid?(value)
      end

      # Build lax type. Constraints are not applicable to lax types hence unwrapping
      #
      # @return [Lax]
      # @api public
      def lax
        type.lax
      end

      # @see Nominal#to_ast
      # @api public
      def to_ast(meta: true)
        [:constrained, [type.to_ast(meta: meta), rule.to_ast]]
      end

      # @api private
      def constructor_type
        type.constructor_type
      end

      private

      # @param [Object] response
      #
      # @return [Boolean]
      #
      # @api private
      def decorate?(response)
        super || response.is_a?(Constructor)
      end
    end
  end
end
