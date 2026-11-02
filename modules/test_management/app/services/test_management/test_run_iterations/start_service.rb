# frozen_string_literal: true

module TestManagement
  module TestRunIterations
    # "Start new iteration" on the run page (or POST …/runs/:id/iterations):
    # re-execute the same set of cases. Requires :add_test_runs and an active run.
    class StartService
      def initialize(user:, run:)
        @user = user
        @run = run
      end

      def call(params = {})
        params = params.to_h.with_indifferent_access
        return failure(:error_unauthorized) unless user.allowed_in_project?(:add_test_runs, run.project)
        return failure(:tm_run_finished) if run.finished?

        name = params[:name].to_s.strip

        iteration = nil
        run.with_lock do
          iteration = Starter.new(run:, user:).start!(name:, source: "manual")
        end
        ServiceResult.success(result: iteration)
      end

      private

      attr_reader :user, :run

      def failure(error)
        errors = ActiveModel::Errors.new(run)
        errors.add(:base, error)
        ServiceResult.failure(result: run, errors:)
      end
    end
  end
end
