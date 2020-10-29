# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class is intended for use with Grape endpoint parameters that
      # have been declared to be of variant-type using the +:types+ option.
      # +MultipleTypeCoercer+ will build a coercer for each type declared
      # in the array passed to +:types+ using {Types.build_coercer}. It will
      # apply these coercers to parameter values in the order given to
      # +:types+, and will return the value returned by the first coercer
      # to successfully coerce the parameter value. Therefore if +String+ is
      # an allowed type it should be declared last, since it will always
      # successfully "coerce" the value.
      class MultipleTypeCoercer
        # Construct a new coercer that will attempt to coerce
        # values to the given list of types in the given order.
        #
        # @param types [Array<Class>] list of allowed types
        # @param method [#call,#parse] method by which values should be
        #   coerced. See class docs for default behaviour.
        def initialize(types, method = nil)
          @method = method.respond_to?(:parse) ? method.method(:parse) : method

          @type_coercers = types.map do |type|
            if Types.multiple? type
              VariantCollectionCoercer.new type, @method
            else
              Types.build_coercer type, strict: !@method.nil?
            end
          end
        end

        # Coerces the given value.
        #
        # @param val [String] value to be coerced, in grape
        #   this should always be a string.
        # @return [Object,InvalidValue] the coerced result, or an instance
        #   of {InvalidValue} if the value could not be coerced.
        def call(val)
          # once the value is coerced by the custom method, its type should be checked
          val = @method.call(val) if @method

          coerced_val = InvalidValue.new

          @type_coercers.each do |coercer|
            coerced_val = coercer.call(val)

            return coerced_val unless coerced_val.is_a?(InvalidValue)
          end

          coerced_val
        end
      end
    end
  end
end
