# frozen_string_literal: true

module TestManagement
  module TestRuns
    # "Cancel run": like completing, statuses are frozen and history records "cancelled".
    class CancelService < FinishService
      private

      def target_state
        "cancelled"
      end

      # CI may cancel the automation run it created (cancelled pipeline).
      def permitted?
        super || (run.automation? && user.allowed_in_project?(:upload_test_results, run.project))
      end
    end
  end
end
