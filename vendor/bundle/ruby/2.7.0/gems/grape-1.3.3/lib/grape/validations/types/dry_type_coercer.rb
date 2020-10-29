# frozen_string_literal: true

require 'dry-types'

module DryTypes
  # Call +Dry.Types()+ to add all registered types to +DryTypes+ which is
  # a container in this case. Check documentation for more information
  # https://dry-rb.org/gems/dry-types/1.2/getting-started/
  include Dry.Types()
end

module Grape
  module Validations
    module Types
      # A base class for classes which must identify a coercer to be used.
      # If the +strict+ argument is true, it won't coerce the given value
      # but check its type. More information there
      # https://dry-rb.org/gems/dry-types/1.2/built-in-types/
      class DryTypeCoercer
        class << self
          # Registers a collection coercer which could be found by a type,
          # see +collection_coercer_for+ method below. This method is meant for inheritors.
          def register_collection(type)
            DryTypeCoercer.collection_coercers[type] = self
          end

          # Returns a collection coercer which corresponds to a given type.
          # Example:
          #
          #    collection_coercer_for(Array)
          #    #=> Grape::Validations::Types::ArrayCoercer
          def collection_coercer_for(type)
            collection_coercers[type]
          end

          # Returns an instance of a coercer for a given type
          def coercer_instance_for(type, strict = false)
            return PrimitiveCoercer.new(type, strict) if type.class == Class

            # in case of a collection (Array[Integer]) the type is an instance of a collection,
            # so we need to figure out the actual type
            collection_coercer_for(type.class).new(type, strict)
          end

          protected

          def collection_coercers
            @collection_coercers ||= {}
          end
        end

        def initialize(type, strict = false)
          @type = type
          @strict = strict
          @scope = strict ? DryTypes::Strict : DryTypes::Params
        end

        # Coerces the given value to a type which was specified during
        # initialization as a type argument.
        #
        # @param val [Object]
        def call(val)
          return if val.nil?

          @coercer[val]
        rescue Dry::Types::CoercionError => _e
          InvalidValue.new
        end

        protected

        attr_reader :scope, :type, :strict
      end
    end
  end
end
