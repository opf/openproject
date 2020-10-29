# frozen_string_literal: true

module Grape
  module Validations
    class SingleAttributeIterator < AttributesIterator
      private

      def yield_attributes(val, attrs)
        attrs.each do |attr_name|
          yield val, attr_name, empty?(val)
        end
      end

      # Primitives like Integers and Booleans don't respond to +empty?+.
      # It could be possible to use +blank?+ instead, but
      #
      #     false.blank?
      #     => true
      def empty?(val)
        val.respond_to?(:empty?) ? val.empty? : val.nil?
      end
    end
  end
end
