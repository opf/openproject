# frozen_string_literal: true

module TestManagement
  module TestRuns
    # Completes or cancels a run: freezes every run case's status (final_status),
    # stamps finished_at/finished_by and writes one history event per case
    # ("Run R12 “Smoke” completed: passed") into the case's History tab.
    class FinishService < TransitionService
      private

      def target_state
        raise TestManagement::AbstractMethodError
      end

      def allowed_from
        TestRun::ACTIVE_STATES
      end

      # completion_source: "manual" (UI) or "automation" (CI closeRun / API).
      def perform(completion_source: "manual", **)
        now = Time.current
        run.update!(state: target_state, finished_at: now, finished_by: user, completion_source:)

        run.run_cases.find_each do |run_case|
          run_case.update_columns(final_status: run_case.status, updated_at: now)
          TestCaseEvent.create!(test_case_id: run_case.test_case_id,
                                user:,
                                action: "run_#{target_state}",
                                created_at: now,
                                details: {
                                  "run_id" => run.id,
                                  "run_name" => run.name,
                                  "status" => run_case.status,
                                  "source" => (completion_source if completion_source == "automation"),
                                  "commit_sha" => run.ci_info["commitSha"].presence
                                }.compact)
        end
      end
    end
  end
end
