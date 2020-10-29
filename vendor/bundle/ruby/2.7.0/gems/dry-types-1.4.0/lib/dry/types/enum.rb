# frozen_string_literal: true

require 'dry/types/decorator'

module Dry
  module Types
    # Enum types can be used to define an enum on top of an existing type
    #
    # @api public
    class Enum
      include Type
      include Dry::Equalizer(:type, :mapping, inspect: false, immutable: true)
      include Decorator
      include Builder

      # @return [Array]
      attr_reader :values

      # @return [Hash]
      attr_reader :mapping

      # @return [Hash]
      attr_reader :inverted_mapping

      # @param [Type] type
      # @param [Hash] options
      # @option options [Array] :values
      #
      # @api private
      def initialize(type, **options)
        super
        @mapping = options.fetch(:mapping).freeze
        @values = @mapping.keys.freeze
        @inverted_mapping = @mapping.invert.freeze
        freeze
      end

      # @return [Object]
      #
      # @api private
      def call_unsafe(input)
        type.call_unsafe(map_value(input))
      end

      # @return [Object]
      #
      # @api private
      def call_safe(input, &block)
        type.call_safe(map_value(input), &block)
      end

      # @see Dry::Types::Constrained#try
      #
      # @api public
      def try(input)
        super(map_value(input))
      end

      # @api private
      def default(*)
        raise '.enum(*values).default(value) is not supported. Call '\
              '.default(value).enum(*values) instead'
      end

      # Check whether a value is in the enum
      alias_method :include?, :valid?

      # @see Nominal#to_ast
      #
      # @api public
      def to_ast(meta: true)
        [:enum, [type.to_ast(meta: meta), mapping]]
      end

      # @return [String]
      #
      # @api public
      def to_s
        PRINTER.(self)
      end
      alias_method :inspect, :to_s

      private

      # Maps a value
      #
      # @param [Object] input
      #
      # @return [Object]
      #
      # @api private
      def map_value(input)
        if input.equal?(Undefined)
          type.call
        elsif mapping.key?(input)
          input
        else
          inverted_mapping.fetch(input, input)
        end
      end
    end
  end
end
