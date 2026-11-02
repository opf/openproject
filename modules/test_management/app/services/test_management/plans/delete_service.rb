# frozen_string_literal: true

module TestManagement
  module Plans
    class DeleteService < TransitionService
      private

      def allowed_from = TestPlan::STATES

      def perform
        plan.test_runs.find_each(&:destroy!)
        plan.destroy!
      end
    end
  end
end
