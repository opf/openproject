# frozen_string_literal: true

module TestManagement
  module TestRunIterations
    # Creates iterations. No permission checks and no locking – callers (StartService,
    # Automation::IngestService) hold the run lock and have authorized the user.
    class Starter
      def initialize(run:, user:)
        @run = run
        @user = user
      end

      # Runs created before iterations existed (or never iterated) get iteration 1 on demand;
      # their existing results and imports are assigned to it. Returns the current iteration.
      def ensure_initial!(attributes = {})
        current = run.current_iteration
        return current if current

        iteration = create_iteration!(1, attributes)
        TestResult.where(run_case_id: run.run_cases.select(:id), iteration_id: nil).update_all(iteration_id: iteration.id)
        AutomationImport.where(test_run_id: run.id, iteration_id: nil).update_all(iteration_id: iteration.id)
        iteration
      end

      # Starts the next iteration and resets every run case to "untested" (results of earlier
      # iterations are kept). A run without any iteration and without results simply gets
      # iteration 1 with the given attributes, nothing to reset.
      def start!(attributes = {})
        if run.current_iteration.nil? && !results_exist?
          return create_iteration!(1, attributes)
        end

        previous = ensure_initial!
        iteration = create_iteration!(previous.number + 1, attributes)
        run.run_cases.where.not(status: "untested").update_all(status: "untested", updated_at: Time.current)
        run.update!(state: "new") if run.state == "in_progress"
        iteration
      end

      private

      attr_reader :run, :user

      # Results, or statuses set without a result (e.g. older data, bulk updates): both
      # mean the run has been executed and the next iteration must reset it.
      def results_exist?
        TestResult.exists?(run_case_id: run.run_cases.select(:id)) ||
          run.run_cases.where.not(status: "untested").exists?
      end

      def create_iteration!(number, attributes)
        attributes = attributes.to_h.symbolize_keys.slice(:name, :source, :external_ref, :ci_metadata, :connection)
        attributes[:name] = attributes[:name].to_s.strip.first(255).presence
        attributes[:source] ||= "manual"
        attributes[:ci_metadata] ||= {}
        run.iterations.create!(number:, created_by: user, **attributes).tap { run.iterations.reset }
      end
    end
  end
end
