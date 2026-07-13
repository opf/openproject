# frozen_string_literal: true

module ResourcePlanners
  module Forms
    class PublicForm < ApplicationForm
      form do |f|
        f.check_box(
          name: :public,
          label: ResourcePlanner.human_attribute_name(:public),
          caption: I18n.t("resource_management.public_caption")
        )
      end
    end
  end
end
