# frozen_string_literal: true

module TestManagement
  module RunCases
    # Changes the status and/or assignee of one case in a run.
    # - requires :execute_test_runs (or :add_test_runs) and an active run;
    # - a status change writes a TestResult (status, optional comment, user, time) in the
    #   run's current iteration;
    # - the first status change away from "untested" moves a "new" run to "in_progress";
    # - manual step results (0020): `step_results` [{ test_step_id, status, actual_result }] (or a
    #   hash keyed by step id, as the run case form posts it) store one row per case step; without a
    #   status the case status is derived from the steps (failed > blocked > all passed > in_progress).
    #   An optional `error_message` is stored as the result's error.
    class UpdateService
      def initialize(user:, model:)
        @user = user
        @run_case = model
      end

      def call(params)
        params = params.to_h.with_indifferent_access
        run_case.errors.clear
        run = run_case.test_run

        return failure(:error_unauthorized) unless permitted?(run)
        return failure(:tm_run_finished) if run.finished?

        status = params[:status].presence
        return failure(:tm_invalid_status) if status && TestRunCase::STATUSES.exclude?(status)

        steps = step_rows(params[:step_results])
        return failure(:tm_invalid_step_result) if steps == :invalid

        status ||= derived_status(steps) if steps.any?

        assignee_given = params.key?(:assigned_to_id)
        assignee_id = params[:assigned_to_id].presence&.to_i
        return failure(:tm_invalid_assignee) if assignee_given && assignee_id && !possible_assignee?(run, assignee_id)

        TestRunCase.transaction do
          run_case.assigned_to_id = assignee_id if assignee_given
          status_changed = status && status != run_case.status
          run_case.status = status if status
          run_case.save!

          error_message = params[:error_message].to_s.strip.presence
          if status_changed || params[:comment].present? || steps.any? || error_message
            result = run_case.results.create!(status: run_case.status, comment: params[:comment].presence, user:,
                                              iteration: run.current_iteration, error_message:)
            steps.each { |row| result.step_results.create!(row) }
          end
          run.update!(state: "in_progress") if run.state == "new" && run_case.status != "untested"
        end

        ServiceResult.success(result: run_case)
      end

      private

      attr_reader :user, :run_case

      def permitted?(run)
        user.allowed_in_project?(:execute_test_runs, run.project) ||
          user.allowed_in_project?(:add_test_runs, run.project)
      end

      # Rows for every case step (in case order) when any step has a status or an actual result;
      # [] when none was given; :invalid for unknown steps or statuses.
      def step_rows(value)
        entries = case value
                  when nil, "" then []
                  when Hash, ActionController::Parameters
                    value.to_h.map { |key, entry| entry.to_h.with_indifferent_access.reverse_merge(test_step_id: key) }
                  when Array then value.map { |entry| entry.to_h.with_indifferent_access }
                  else return :invalid
                  end
        entries = entries.reject { |entry| entry[:status].blank? && entry[:actual_result].blank? }
        return [] if entries.empty?

        case_steps = run_case.test_case.steps.to_a
        by_id = entries.index_by { |entry| entry[:test_step_id].to_s }
        return :invalid unless (by_id.keys - case_steps.map { |step| step.id.to_s }).empty?
        return :invalid unless entries.all? { |entry| entry[:status].blank? || TestStepResult::STATUSES.include?(entry[:status].to_s) }

        case_steps.each_with_index.map do |step, index|
          entry = by_id[step.id.to_s] || {}
          { kind: "case", test_step: step, position: index, match_method: "manual",
            step_action: step.action.to_s.first(TestStepResult::TITLE_LIMIT),
            status: entry[:status].presence || "untested",
            actual_result: entry[:actual_result].to_s.strip.first(TestStepResult::ACTUAL_RESULT_LIMIT).presence }
        end
      end

      def derived_status(rows)
        statuses = rows.pluck(:status)
        return "failed" if statuses.include?("failed")
        return "blocked" if statuses.include?("blocked")
        return "passed" if statuses.all?("passed")

        "in_progress"
      end

      def possible_assignee?(run, id)
        TestManagement::Assignees.possible?(run.project, id)
      end

      def failure(error)
        run_case.errors.add(:base, error)
        ServiceResult.failure(result: run_case, errors: run_case.errors)
      end
    end
  end
end
