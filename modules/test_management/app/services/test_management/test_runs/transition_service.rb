# frozen_string_literal: true

module TestManagement
  module TestRuns
    # Base for state changes of a run (complete / cancel / reopen).
    # Returns a ServiceResult; usable from controllers and from automation
    # (e.g. a CI result ingest calling CompleteService with its API user).
    class TransitionService
      def initialize(user:, model:)
        @user = user
        @run = model
      end

      def call(**)
        return failure(:error_unauthorized) unless permitted?
        return failure(:tm_invalid_transition) unless allowed_from.include?(run.state)

        TestRun.transaction do
          perform(**)
        end
        ServiceResult.success(result: run)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError => e
        run.errors.add(:base, e.message)
        ServiceResult.failure(result: run, errors: run.errors)
      end

      private

      attr_reader :user, :run

      def permitted?
        user.allowed_in_project?(:add_test_runs, run.project)
      end

      def allowed_from
        raise TestManagement::AbstractMethodError
      end

      def perform(**)
        raise TestManagement::AbstractMethodError
      end

      def failure(error)
        run.errors.add(:base, error)
        ServiceResult.failure(result: run, errors: run.errors)
      end
    end
  end
end
