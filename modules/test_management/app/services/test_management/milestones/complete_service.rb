# frozen_string_literal: true

module TestManagement
  module Milestones
    # Completing does not touch the runs: open runs stay open (they can still be finished),
    # but no new runs can be assigned to a completed milestone.
    class CompleteService < TransitionService
      private

      def allowed_from = %w[open started]

      def perform
        milestone.update!(status: "completed", completed_at: Time.current)
      end
    end
  end
end
