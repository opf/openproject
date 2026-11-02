# frozen_string_literal: true

module TestManagement
  module TestRuns
    # Adds a (new or changed) test case to every active run of its project whose
    # selection mode is "all" or "dynamic" and whose filter it matches.
    # Called from TestCase after_create_commit / after_update_commit.
    # Cases are never removed automatically (results may already exist).
    class AutoAddService
      def initialize(test_case)
        @test_case = test_case
      end

      def call
        return [] if test_case.deleted?

        runs = TestRun.active
                      .where(project_id: test_case.project_id, selection_mode: %w[all dynamic])
                      .where.not(id: TestRunCase.where(test_case_id: test_case.id).select(:test_run_id))

        runs.select { |run| run.matches?(test_case) }.each do |run|
          run.run_cases.create!(test_case:, assigned_to_id: run.assigned_to_id, status: "untested")
        end
      end

      private

      attr_reader :test_case
    end
  end
end
