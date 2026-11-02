# frozen_string_literal: true

module TestManagement
  # One status change of a case inside a run (result history within the run).
  class TestResult < ApplicationRecord
    self.table_name = "tm_test_results"
    self.record_timestamps = false

    belongs_to :run_case, class_name: "TestManagement::TestRunCase", inverse_of: :results
    belongs_to :iteration, class_name: "TestManagement::TestRunIteration", optional: true, inverse_of: :results
    belongs_to :user, optional: true
    belongs_to :import, class_name: "TestManagement::AutomationImport", optional: true, inverse_of: :results
    # Per-step outcomes (0020): case steps first (by position), then unmatched reported steps.
    has_many :step_results, -> { order(:position, :id) },
             class_name: "TestManagement::TestStepResult",
             foreign_key: :result_id,
             inverse_of: :result,
             dependent: :delete_all

    SOURCES = %w[manual automation].freeze
    # The printed error (0020): message and stack trace, plain text, capped.
    ERROR_MESSAGE_LIMIT = 4000
    ERROR_TRACE_LIMIT = 16_000

    validates :status, inclusion: { in: TestRunCase::STATUSES }
    validates :source, inclusion: { in: SOURCES }

    # { run_case_id => latest result } in two queries (MAX(id) per run case, optionally within
    # one iteration). Used by the run page and the run export instead of preloading every result.
    def self.latest_by_run_case(run_case_ids, iteration_id: nil)
      scope = where(run_case_id: run_case_ids)
      scope = scope.where(iteration_id:) if iteration_id
      where(id: scope.group(:run_case_id).select(Arel.sql("MAX(id)"))).includes(:user, :step_results).index_by(&:run_case_id)
    end

    def automation?
      source == "automation"
    end

    def error?
      error_message.present? || error_trace.present?
    end

    # The first failed case step (for "Failed at step 3"), from loaded step results.
    def failed_step
      step_results.find { |step| step.case_step? && step.failed? }
    end

    def details_hash
      (details || {}).stringify_keys
    end

    before_create { self.created_at ||= Time.current }
    before_save :cap_error

    private

    def cap_error
      return unless has_attribute?(:error_message)

      self.error_message = error_message.to_s.first(ERROR_MESSAGE_LIMIT).presence if error_message_changed?
      self.error_trace = error_trace.to_s.first(ERROR_TRACE_LIMIT).presence if error_trace_changed?
    end
  end
end
