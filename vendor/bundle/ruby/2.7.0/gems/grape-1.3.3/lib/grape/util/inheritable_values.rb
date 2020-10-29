# frozen_string_literal: true

require_relative 'base_inheritable'

module Grape
  module Util
    class InheritableValues < BaseInheritable
      def [](name)
        values[name]
      end

      def []=(name, value)
        new_values[name] = value
      end

      def merge(new_hash)
        values.merge!(new_hash)
      end

      def to_hash
        values
      end

      protected

      def values
        @inherited_values.merge(@new_values)
      end
    end
  end
end
