# frozen_string_literal: true

module TestManagement
  module Milestones
    # Unlike some tools, a completed milestone can be reopened (e.g. a release slipped).
    class ReopenService < TransitionService
      private

      def allowed_from = %w[completed]

      def perform
        milestone.update!(status: milestone.started_at ? "started" : "open", completed_at: nil)
      end
    end
  end
end
