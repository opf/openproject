# frozen_string_literal: true

require 'dry/core/deprecations'

module Dry
  module Types
    # Common API for building types and composition
    #
    # @api public
    module Builder
      include Dry::Core::Constants

      # @return [Class]
      #
      # @api private
      def constrained_type
        Constrained
      end

      # @return [Class]
      #
      # @api private
      def constructor_type
        Constructor
      end

      # Compose two types into a Sum type
      #
      # @param [Type] other
      #
      # @return [Sum, Sum::Constrained]
      #
      # @api private
      def |(other)
        klass = constrained? && other.constrained? ? Sum::Constrained : Sum
        klass.new(self, other)
      end

      # Turn a type into an optional type
      #
      # @return [Sum]
      #
      # @api public
      def optional
        Types['strict.nil'] | self
      end

      # Turn a type into a constrained type
      #
      # @param [Hash] options constraining rule (see {Types.Rule})
      #
      # @return [Constrained]
      #
      # @api public
      def constrained(options)
        constrained_type.new(self, rule: Types.Rule(options))
      end

      # Turn a type into a type with a default value
      #
      # @param [Object] input
      # @param [Hash] options
      # @param [#call,nil] block
      #
      # @raise [ConstraintError]
      #
      # @return [Default]
      #
      # @api public
      def default(input = Undefined, options = EMPTY_HASH, &block)
        unless input.frozen? || options[:shared]
          where = Dry::Core::Deprecations::STACK.()
          Dry::Core::Deprecations.warn(
            "#{input.inspect} is mutable."\
            ' Be careful: types will return the same instance of the default'\
            ' value every time. Call `.freeze` when setting the default'\
            ' or pass `shared: true` to discard this warning.'\
            "\n#{where}",
            tag: :'dry-types'
          )
        end

        value = input.equal?(Undefined) ? block : input

        if value.respond_to?(:call) || valid?(value)
          Default[value].new(self, value)
        else
          raise ConstraintError.new("default value #{value.inspect} violates constraints", value)
        end
      end

      # Define an enum on top of the existing type
      #
      # @param [Array] values
      #
      # @return [Enum]
      #
      # @api public
      def enum(*values)
        mapping =
          if values.length == 1 && values[0].is_a?(::Hash)
            values[0]
          else
            ::Hash[values.zip(values)]
          end

        Enum.new(constrained(included_in: mapping.keys), mapping: mapping)
      end

      # Turn a type into a lax type that will rescue from type-errors and
      # return the original input
      #
      # @return [Lax]
      #
      # @api public
      def lax
        Lax.new(self)
      end

      # Define a constructor for the type
      #
      # @param [#call,nil] constructor
      # @param [Hash] options
      # @param [#call,nil] block
      #
      # @return [Constructor]
      #
      # @api public
      def constructor(constructor = nil, **options, &block)
        constructor_type.new(with(**options), fn: constructor || block)
      end
      alias_method :append, :constructor
      alias_method :prepend, :constructor
      alias_method :>>, :constructor
      alias_method :<<, :constructor
    end
  end
end

require 'dry/types/default'
require 'dry/types/constrained'
require 'dry/types/enum'
require 'dry/types/lax'
require 'dry/types/sum'
