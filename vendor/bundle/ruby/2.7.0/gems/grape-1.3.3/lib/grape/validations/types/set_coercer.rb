# frozen_string_literal: true

require 'set'
require_relative 'array_coercer'

module Grape
  module Validations
    module Types
      # Takes the given array and converts it to a set. Every element of the set
      # is also coerced.
      class SetCoercer < ArrayCoercer
        register_collection Set

        def initialize(type, strict = false)
          super

          @coercer = nil
        end

        def call(value)
          return InvalidValue.new unless value.is_a?(Array)

          coerce_elements(value)
        end

        protected

        def coerce_elements(collection)
          collection.each_with_object(Set.new) do |elem, memo|
            coerced_elem = elem_coercer.call(elem)

            return coerced_elem if coerced_elem.is_a?(InvalidValue)

            memo.add(coerced_elem)
          end
        end
      end
    end
  end
end
