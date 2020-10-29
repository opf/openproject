# frozen_string_literal: true

require_relative 'base_inheritable'

module Grape
  module Util
    class StackableValues < BaseInheritable
      # Even if there is no value, an empty array will be returned.
      def [](name)
        inherited_value = inherited_values[name]
        new_value = new_values[name]

        return new_value || [] unless inherited_value

        concat_values(inherited_value, new_value)
      end

      def []=(name, value)
        new_values[name] ||= []
        new_values[name].push value
      end

      def to_hash
        keys.each_with_object({}) do |key, result|
          result[key] = self[key]
        end
      end

      protected

      def concat_values(inherited_value, new_value)
        return inherited_value unless new_value

        [].tap do |value|
          value.concat(inherited_value)
          value.concat(new_value)
        end
      end
    end
  end
end
