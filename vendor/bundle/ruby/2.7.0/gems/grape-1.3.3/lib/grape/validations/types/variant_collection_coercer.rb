# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class wraps {MultipleTypeCoercer}, for use with collections
      # that allow members of more than one type.
      class VariantCollectionCoercer
        # Construct a new coercer that will attempt to coerce
        # a list of values such that all members are of one of
        # the given types. The container may also optionally be
        # coerced to a +Set+. An arbitrary coercion +method+ may
        # be supplied, which will be passed the entire collection
        # as a parameter and should return a new collection, or
        # may return the same one if no coercion was required.
        #
        # @param types [Array<Class>,Set<Class>] list of allowed types,
        #   also specifying the container type
        # @param method [#call,#parse] method by which values should be coerced
        def initialize(types, method = nil)
          @types = types
          @method = method.respond_to?(:parse) ? method.method(:parse) : method

          # If we have a coercion method, pass it in here to save
          # building another one, even though we call it directly.
          @member_coercer = MultipleTypeCoercer.new types, method
        end

        # Coerce the given value.
        #
        # @param value [Array<String>] collection of values to be coerced
        # @return [Array<Object>,Set<Object>,InvalidValue]
        #   the coerced result, or an instance
        #   of {InvalidValue} if the value could not be coerced.
        def call(value)
          return unless value.is_a? Array

          value =
            if @method
              @method.call(value)
            else
              value.map { |v| @member_coercer.call(v) }
            end
          return Set.new value if @types.is_a? Set

          value
        end
      end
    end
  end
end
