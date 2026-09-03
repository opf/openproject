# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class AttentionComponent < ApplicationComponent
      def initialize(items:, project:, selected_view:)
        super
        @items = items.select { |_key, item| item[:count].positive? }
        @project = project
        @selected_view = selected_view
      end

      def item_path(key)
        project_risk_log_path(@project, view: key)
      end

      def selected?(key)
        @selected_view == key.to_s
      end
    end
  end
end
