# frozen_string_literal: true

require 'set'

require 'dry/equalizer'

require 'dry/configurable/constants'
require 'dry/configurable/config'

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :value, :options, inspect: false)

      OPTIONS = %i[input default reader constructor settings].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      CLONABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api private
      attr_reader :name

      # @api private
      attr_reader :writer_name

      # @api private
      attr_reader :input

      # @api private
      attr_reader :default

      # @api private
      attr_reader :options

      # Specialized Setting which includes nested settings
      #
      # @api private
      class Nested < Setting
        CONSTRUCTOR = Config.method(:new)

        # @api private
        def pristine
          with(input: input.pristine)
        end

        # @api private
        def constructor
          CONSTRUCTOR
        end
      end

      # @api private
      def initialize(name, input: Undefined, default: Undefined, **options)
        @name = name
        @writer_name = :"#{name}="
        @input = input.equal?(Undefined) ? default : input
        @default = default
        @options = options

        evaluate if input_defined?
      end

      # @api private
      def input_defined?
        !input.equal?(Undefined)
      end

      # @api private
      def value
        @value ||= evaluate
      end

      # @api private
      def evaluated?
        instance_variable_defined?(:@value)
      end

      # @api private
      def nested(settings)
        Nested.new(name, input: settings, **options)
      end

      # @api private
      def pristine
        with(input: Undefined)
      end

      # @api private
      def with(new_opts)
        self.class.new(name, input: input, default: default, **options, **new_opts)
      end

      # @api private
      def constructor
        options[:constructor] || DEFAULT_CONSTRUCTOR
      end

      # @api private
      def reader?
        options[:reader].equal?(true)
      end

      # @api private
      def writer?(meth)
        writer_name.equal?(meth)
      end

      # @api private
      def clonable_value?
        CLONABLE_VALUE_TYPES.any? { |type| value.is_a?(type) }
      end

      private

      # @api private
      def initialize_copy(source)
        super
        @value = source.value.dup if source.input_defined? && source.clonable_value?
        @options = source.options.dup
      end

      # @api private
      def evaluate
        @value = constructor[input.equal?(Undefined) ? nil : input]
      end
    end
  end
end
