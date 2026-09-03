# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class PageHeaderComponent < ApplicationComponent
      def initialize(project:, risk_type: nil)
        super
        @project = project
        @risk_type = risk_type
      end
    end
  end
end
