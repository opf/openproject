# frozen_string_literal: true

module TestManagement
  module Labels
    class SetAttributesService < ::BaseServices::SetAttributes
      private

      def set_attributes(params)
        attributes = params.to_h.symbolize_keys
        if attributes.key?(:name)
          attributes[:name] = TestManagement::Label.normalize_name(attributes[:name])
        end
        attributes.delete(:color) if attributes.key?(:color) && attributes[:color].blank?
        super(attributes)
      end
    end
  end
end
