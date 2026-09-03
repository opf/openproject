# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class MetricsComponent < ApplicationComponent
      METRICS = %i[monitored total_exposure highest_exposure requiring_attention].freeze

      def initialize(metrics:, project:)
        super
        @metrics = metrics
        @project = project
      end

      def metric_path(metric)
        project_risk_log_path(@project, view: metric_view(metric))
      end

      def selected?(metric)
        params[:view] == metric_view(metric)
      end

      def metric_value(metric)
        value = @metrics.fetch(metric).fetch(:value)
        return helpers.number_to_currency(value, precision: 0) if %i[total_exposure highest_exposure].include?(metric)

        value.to_s
      end

      def metric_accessible_label(metric)
        label = t("risk_management.risk_log.dashboard.metrics.#{metric}")
        "#{label}: #{metric_value(metric)}"
      end

      private

      def metric_view(metric)
        { monitored: "monitored", total_exposure: "monitored", highest_exposure: "highest_exposure",
          requiring_attention: "attention" }.fetch(metric)
      end
    end
  end
end
