# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class WorkflowComponent < ApplicationComponent
      COLORS = %i[emphasis accent_emphasis attention_emphasis success_emphasis].freeze

      def initialize(workflow:, project:)
        super
        @workflow = workflow
        @project = project
      end

      def total
        @workflow[:statuses].sum { |status| status[:current] }
      end

      def percentage(status)
        return 0 if total.zero?

        status[:current].to_f / total * 100
      end

      def status_path(status)
        filters = [{ status_id: { operator: "=", values: [status[:id].to_s] } }]
        project_risk_log_path(@project, filters: filters.to_json)
      end

      def color(index)
        COLORS.fetch(index)
      end

      def legend_color(index)
        %i[default accent attention success].fetch(index)
      end
    end
  end
end
