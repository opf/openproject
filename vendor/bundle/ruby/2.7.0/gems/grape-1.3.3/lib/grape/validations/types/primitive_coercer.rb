# frozen_string_literal: true

require_relative 'dry_type_coercer'

module Grape
  module Validations
    module Types
      # Coerces the given value to a type defined via a +type+ argument during
      # initialization. When +strict+ is true, it doesn't coerce a value but check
      # that it has the proper type.
      class PrimitiveCoercer < DryTypeCoercer
        MAPPING = {
          Grape::API::Boolean => DryTypes::Params::Bool,
          BigDecimal          => DryTypes::Params::Decimal,

          # unfortunately, a +Params+ scope doesn't contain String
          String              => DryTypes::Coercible::String
        }.freeze

        STRICT_MAPPING = {
          Grape::API::Boolean => DryTypes::Strict::Bool,
          BigDecimal          => DryTypes::Strict::Decimal
        }.freeze

        def initialize(type, strict = false)
          super

          @type = type

          @coercer = if strict
                       STRICT_MAPPING.fetch(type) { scope.const_get(type.name) }
                     else
                       MAPPING.fetch(type) { scope.const_get(type.name) }
                     end
        end

        def call(val)
          return InvalidValue.new if reject?(val)
          return nil if val.nil? || treat_as_nil?(val)
          return '' if val == ''

          super
        end

        protected

        attr_reader :type

        # This method maintains logic which was defined by Virtus. For example,
        # dry-types is ok to convert an array or a hash to a string, it is supported,
        # but Virtus wouldn't accept it. So, this method only exists to not introduce
        # breaking changes.
        def reject?(val)
          (val.is_a?(Array) && type == String) ||
            (val.is_a?(String) && type == Hash) ||
            (val.is_a?(Hash) && type == String)
        end

        # Dry-Types treats an empty string as invalid. However, Grape considers an empty string as
        # absence of a value and coerces it into nil. See a discussion there
        # https://github.com/ruby-grape/grape/pull/2045
        def treat_as_nil?(val)
          val == '' && type == Grape::API::Boolean
        end
      end
    end
  end
end
