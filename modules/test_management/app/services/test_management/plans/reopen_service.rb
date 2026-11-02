# frozen_string_literal: true

module TestManagement
  module Plans
    class ReopenService < TransitionService
      private

      def allowed_from = %w[completed]

      def perform
        plan.update!(state: "active", finished_at: nil, finished_by: nil)
      end
    end
  end
end
