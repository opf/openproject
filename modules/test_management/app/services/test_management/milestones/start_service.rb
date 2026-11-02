# frozen_string_literal: true

module TestManagement
  module Milestones
    class StartService < TransitionService
      private

      def allowed_from = %w[open]

      def perform
        milestone.update!(status: "started", started_at: Time.current,
                          start_date: milestone.start_date || Date.current)
      end
    end
  end
end
