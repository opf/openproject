# frozen_string_literal: true

module RiskManagement
  class PlanForm < ApplicationForm
    form do |f|
      f.hidden(name: :lock_version)
      f.rich_text_area(
        name: :body,
        label: Plan.human_attribute_name(:body),
        visually_hide_label: true,
        rich_text_options: {
          with_text_formatting: true,
          macros: true,
          showAttachments: false
        }
      )
      f.group(layout: :horizontal) do |buttons|
        buttons.submit(name: :save, label: I18n.t(:button_save), scheme: :primary)
        buttons.button(
          name: :cancel,
          label: I18n.t(:button_cancel),
          tag: :a,
          href: helpers.project_risk_management_plan_path(model.project)
        )
      end
    end
  end
end
