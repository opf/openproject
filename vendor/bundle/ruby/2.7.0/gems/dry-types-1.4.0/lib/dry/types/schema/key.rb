# frozen_string_literal: true

require 'dry/equalizer'
require 'dry/core/deprecations'

module Dry
  module Types
    # Schema is a hash with explicit member types defined
    #
    # @api public
    class Schema < Hash
      # Proxy type for schema keys. Contains only key name and
      # whether it's required or not. All other calls deletaged
      # to the wrapped type.
      #
      # @see Dry::Types::Schema
      class Key
        extend ::Dry::Core::Deprecations[:'dry-types']
        include Type
        include Dry::Equalizer(:name, :type, :options, inspect: false, immutable: true)
        include Decorator
        include Builder
        include Printable

        # @return [Symbol]
        attr_reader :name

        # @api private
        def initialize(type, name, required: Undefined, **options)
          required = Undefined.default(required) do
            type.meta.fetch(:required) { !type.meta.fetch(:omittable, false) }
          end

          unless name.is_a?(::Symbol)
            raise ArgumentError, "Schemas can only contain symbol keys, #{name.inspect} given"
          end

          super(type, name, required: required, **options)
          @name = name
        end

        # @api private
        def call_safe(input, &block)
          type.call_safe(input, &block)
        end

        # @api private
        def call_unsafe(input)
          type.call_unsafe(input)
        end

        # @see Dry::Types::Nominal#try
        #
        # @api public
        def try(input, &block)
          type.try(input, &block)
        end

        # Whether the key is required in schema input
        #
        # @return [Boolean]
        #
        # @api public
        def required?
          options.fetch(:required)
        end

        # Control whether the key is required
        #
        # @overload required
        #   @return [Boolean]
        #
        # @overload required(required)
        #   Change key's "requireness"
        #
        #   @param [Boolean] required New value
        #   @return [Dry::Types::Schema::Key]
        #
        # @api public
        def required(required = Undefined)
          if Undefined.equal?(required)
            options.fetch(:required)
          else
            with(required: required)
          end
        end

        # Make key not required
        #
        # @return [Dry::Types::Schema::Key]
        #
        # @api public
        def omittable
          required(false)
        end

        # Turn key into a lax type. Lax types are not strict hence such keys are not required
        #
        # @return [Lax]
        #
        # @api public
        def lax
          __new__(type.lax).required(false)
        end

        # Make wrapped type optional
        #
        # @return [Key]
        #
        # @api public
        def optional
          __new__(type.optional)
        end

        # Dump to internal AST representation
        #
        # @return [Array]
        #
        # @api public
        def to_ast(meta: true)
          [
            :key,
            [
              name,
              required,
              type.to_ast(meta: meta)
            ]
          ]
        end

        # @see Dry::Types::Meta#meta
        #
        # @api public
        def meta(data = Undefined)
          if Undefined.equal?(data) || !data.key?(:omittable)
            super
          else
            self.class.warn(
              'Using meta for making schema keys is deprecated, ' \
              'please use .omittable or .required(false) instead' \
              "\n" + Core::Deprecations::STACK.()
            )
            super.required(!data[:omittable])
          end
        end

        private

        # @api private
        def decorate?(response)
          response.is_a?(Type)
        end
      end
    end
  end
end
