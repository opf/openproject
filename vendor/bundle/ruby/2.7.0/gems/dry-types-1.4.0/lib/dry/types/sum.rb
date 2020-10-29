# frozen_string_literal: true

require 'dry/types/options'
require 'dry/types/meta'

module Dry
  module Types
    # Sum type
    #
    # @api public
    class Sum
      include Type
      include Builder
      include Options
      include Meta
      include Printable
      include Dry::Equalizer(:left, :right, :options, :meta, inspect: false, immutable: true)

      # @return [Type]
      attr_reader :left

      # @return [Type]
      attr_reader :right

      # @api private
      class Constrained < Sum
        # @return [Dry::Logic::Operations::Or]
        def rule
          left.rule | right.rule
        end

        # @return [true]
        def constrained?
          true
        end
      end

      # @param [Type] left
      # @param [Type] right
      # @param [Hash] options
      #
      # @api private
      def initialize(left, right, **options)
        super
        @left, @right = left, right
        freeze
      end

      # @return [String]
      #
      # @api public
      def name
        [left, right].map(&:name).join(' | ')
      end

      # @return [false]
      #
      # @api public
      def default?
        false
      end

      # @return [false]
      #
      # @api public
      def constrained?
        false
      end

      # @return [Boolean]
      #
      # @api public
      def optional?
        primitive?(nil)
      end

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_unsafe(input)
        left.call_safe(input) { right.call_unsafe(input) }
      end

      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def call_safe(input, &block)
        left.call_safe(input) { right.call_safe(input, &block) }
      end

      # @param [Object] input
      #
      # @api public
      def try(input)
        left.try(input) do
          right.try(input) do |failure|
            if block_given?
              yield(failure)
            else
              failure
            end
          end
        end
      end

      # @api private
      def success(input)
        if left.valid?(input)
          left.success(input)
        elsif right.valid?(input)
          right.success(input)
        else
          raise ArgumentError, "Invalid success value '#{input}' for #{inspect}"
        end
      end

      # @api private
      def failure(input, _error = nil)
        if !left.valid?(input)
          left.failure(input, left.try(input).error)
        else
          right.failure(input, right.try(input).error)
        end
      end

      # @param [Object] value
      #
      # @return [Boolean]
      #
      # @api private
      def primitive?(value)
        left.primitive?(value) || right.primitive?(value)
      end

      # Manage metadata to the type. If the type is an optional, #meta delegates
      # to the right branch
      #
      # @see [Meta#meta]
      #
      # @api public
      def meta(data = Undefined)
        if Undefined.equal?(data)
          optional? ? right.meta : super
        elsif optional?
          self.class.new(left, right.meta(data), **options)
        else
          super
        end
      end

      # @see Nominal#to_ast
      #
      # @api public
      def to_ast(meta: true)
        [:sum, [left.to_ast(meta: meta), right.to_ast(meta: meta), meta ? self.meta : EMPTY_HASH]]
      end

      # @param [Hash] options
      #
      # @return [Constrained,Sum]
      #
      # @see Builder#constrained
      #
      # @api public
      def constrained(options)
        if optional?
          right.constrained(options).optional
        else
          super
        end
      end

      # Wrap the type with a proc
      #
      # @return [Proc]
      #
      # @api public
      def to_proc
        proc { |value| self.(value) }
      end
    end
  end
end
