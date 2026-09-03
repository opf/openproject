# frozen_string_literal: true

module RiskManagement
  module Admin
    class SettingsForm < ApplicationForm
      form do |form|
        impact_threshold_field(form, :impact_very_low_max)
        impact_threshold_field(form, :impact_low_max)
        impact_threshold_field(form, :impact_medium_max)
        impact_threshold_field(form, :impact_high_max)

        form.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
      end

      private

      def impact_threshold_field(form, name)
        form.text_field(
          name:,
          label: I18n.t("risk_management.admin.impact_thresholds.#{name}.label"),
          caption: I18n.t("risk_management.admin.impact_thresholds.caption", currency: Setting.costs_currency),
          type: "number",
          min: 0,
          step: 1,
          required: true,
          input_width: :medium,
          trailing_visual: { text: { text: Setting.costs_currency } }
        )
      end
    end
  end
end
