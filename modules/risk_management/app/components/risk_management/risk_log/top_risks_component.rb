# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class TopRisksComponent < ApplicationComponent
      def initialize(risks:, project:)
        super
        @risks = risks
        @project = project
      end

      def risk_path(risk)
        project_risk_log_details_path(@project, risk)
      end

      def formatted_value(value)
        helpers.number_to_currency(value, precision: 0)
      end

      def formatted_likelihood(value)
        helpers.number_to_percentage(value, precision: 2, strip_insignificant_zeros: true)
      end

      def response(entry)
        entry[:response] || I18n.t("risk_management.risk_log.response.not_specified")
      end

      def percentage(value)
        return 0 if maximum_value.zero?

        (value.to_f / maximum_value * 100).round
      end

      private

      def maximum_value
        @maximum_value ||= @risks.first&.fetch(:value, 0).to_f
      end
    end
  end
end
