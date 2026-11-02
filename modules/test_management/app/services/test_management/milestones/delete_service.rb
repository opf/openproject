# frozen_string_literal: true

module TestManagement
  module Milestones
    # Runs stay and become unassigned (FK nullify); sub-milestones become top-level.
    class DeleteService < TransitionService
      private

      def allowed_from = Milestone::STATUSES

      def perform
        milestone.destroy!
      end
    end
  end
end
