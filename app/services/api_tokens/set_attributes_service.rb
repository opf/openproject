# frozen_string_literal: true

module APITokens
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_default_attributes(_params)
      model.change_by_system do
        model.user = user if model.user.nil?
      end
    end
  end
end
