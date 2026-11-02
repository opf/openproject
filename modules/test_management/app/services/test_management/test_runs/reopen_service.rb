# frozen_string_literal: true

module TestManagement
  module TestRuns
    # Reopens a completed/cancelled run (back to in_progress). Frozen statuses are
    # released; the history events written on finishing are kept.
    class ReopenService < TransitionService
      private

      def allowed_from
        TestRun::FINISHED_STATES
      end

      def perform(**)
        run.update!(state: "in_progress", finished_at: nil, finished_by: nil, completion_source: nil)
        run.run_cases.update_all(final_status: nil, updated_at: Time.current)
        SyncCasesService.new(run).call
      end
    end
  end
end
