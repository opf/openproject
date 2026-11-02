# frozen_string_literal: true

module TestManagement
  module Plans
    class CompleteService < TransitionService
      private

      def allowed_from = %w[active]

      def perform
        plan.test_runs.active.find_each do |run|
          result = TestRuns::CompleteService.new(user:, model: run).call
          raise ActiveRecord::RecordInvalid, run unless result.success?
        end
        plan.update!(state: "completed", finished_at: Time.current, finished_by: user)
      end
    end
  end
end
