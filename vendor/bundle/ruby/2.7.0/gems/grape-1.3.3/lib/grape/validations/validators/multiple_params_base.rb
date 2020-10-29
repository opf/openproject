# frozen_string_literal: true

module Grape
  module Validations
    class MultipleParamsBase < Base
      def validate!(params)
        attributes = MultipleAttributesIterator.new(self, @scope, params)
        array_errors = []

        attributes.each do |resource_params|
          begin
            validate_params!(resource_params)
          rescue Grape::Exceptions::Validation => e
            array_errors << e
          end
        end

        raise Grape::Exceptions::ValidationArrayErrors, array_errors if array_errors.any?
      end

      private

      def keys_in_common(resource_params)
        return [] unless resource_params.is_a?(Hash)
        all_keys & resource_params.keys.map! { |attr| @scope.full_name(attr) }
      end

      def all_keys
        attrs.map { |attr| @scope.full_name(attr) }
      end
    end
  end
end
