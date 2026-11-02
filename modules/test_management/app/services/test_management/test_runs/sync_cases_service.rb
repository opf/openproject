# frozen_string_literal: true

module TestManagement
  module TestRuns
    # Brings the run's cases in line with its selection while the run is active:
    # - all / dynamic: adds every matching case that is not in the run yet;
    # - specific: adds newly selected cases and removes deselected ones
    #   (only when a selection was submitted, see TestRun#selected_case_ids).
    # New run cases start "untested" and are assigned to the run's assignee.
    class SyncCasesService
      def initialize(run)
        @run = run
      end

      def call
        return run unless run.active?

        if run.selection_mode == "specific"
          sync_specific
        else
          run.add_cases!
        end
        run.selected_case_ids = nil
        run
      end

      private

      attr_reader :run

      def sync_specific
        ids = run.selected_case_ids
        return if ids.nil?

        run.run_cases.where.not(test_case_id: ids).destroy_all
        run.add_cases!(run.project.tm_test_cases.not_deleted.where(id: ids).order(:id))
      end
    end
  end
end
