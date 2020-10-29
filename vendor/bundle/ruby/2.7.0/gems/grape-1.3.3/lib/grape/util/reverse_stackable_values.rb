# frozen_string_literal: true

require_relative 'stackable_values'

module Grape
  module Util
    class ReverseStackableValues < StackableValues
      protected

      def concat_values(inherited_value, new_value)
        return inherited_value unless new_value

        [].tap do |value|
          value.concat(new_value)
          value.concat(inherited_value)
        end
      end
    end
  end
end
