# frozen_string_literal: true

module Grape
  module Validations
    class MultipleAttributesIterator < AttributesIterator
      private

      def yield_attributes(resource_params, _attrs)
        yield resource_params
      end
    end
  end
end
