# frozen_string_literal: true

module RiskManagement
  module Admin
    class CategoryForm < ApplicationForm
      form do |form|
        form.text_field(
          name: :name,
          label: RiskCategory.human_attribute_name(:name),
          required: true,
          input_width: :medium
        )
        form.color_select_list(
          name: :color_id,
          label: RiskCategory.human_attribute_name(:color_id),
          input_width: :medium
        )
        form.check_box(
          name: :active,
          label: RiskCategory.human_attribute_name(:active)
        )
        form.group(layout: :horizontal) do |buttons|
          buttons.submit(name: :save, label: I18n.t(:button_save), scheme: :primary)
          buttons.button(
            name: :cancel,
            label: I18n.t(:button_cancel),
            tag: :a,
            href: helpers.risk_management_admin_categories_path
          )
        end
      end
    end
  end
end
