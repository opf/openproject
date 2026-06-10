# frozen_string_literal: true

module ResourcePlanners
  module Forms
    class FavoriteForm < ApplicationForm
      form do |f|
        f.check_box(
          name: :favorite,
          label: ResourcePlanner.human_attribute_name(:favorite),
          caption: I18n.t("resource_management.favorite_caption")
        )
      end
    end
  end
end
