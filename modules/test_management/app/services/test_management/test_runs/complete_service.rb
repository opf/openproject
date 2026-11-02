# frozen_string_literal: true

module TestManagement
  module TestRuns
    # "Complete run": freeze statuses and record them in each case's history.
    # Also allowed for users with :upload_test_results so an automation ingest
    # can complete the run it reported into.
    class CompleteService < FinishService
      private

      def target_state
        "completed"
      end

      def permitted?
        super || user.allowed_in_project?(:upload_test_results, run.project)
      end
    end
  end
end
