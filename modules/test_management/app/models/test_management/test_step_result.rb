# frozen_string_literal: true

module TestManagement
  # Outcome of one step within a result (0020).
  # - kind "case": a step of the test case (test_step, nil once the step was deleted; step_action is
  #   a snapshot of its action). Written by automated uploads (reported steps mapped to the case
  #   steps, see Automation::StepMatcher) and by manual execution (status + actual_result).
  # - kind "reported": a reported step that matched no case step (kept for the record).
  # details: { "substeps" => [{ "title", "status", "durationMs", "error" }],
  #            "attachments" => [{ "name", "path", "attachmentId" }], "reported" => [titles] }
  # All texts are plain text: they are escaped when shown and never rendered as HTML.
  class TestStepResult < ApplicationRecord
    self.table_name = "tm_test_step_results"
    self.record_timestamps = false

    STATUSES = %w[passed failed blocked skipped untested].freeze
    # Worst first: several reported steps mapped to one case step → the worst status wins.
    PRECEDENCE = %w[failed blocked passed skipped untested].freeze
    KINDS = %w[case reported].freeze
    MATCH_METHODS = %w[marker position title manual].freeze

    TITLE_LIMIT = 1000
    MESSAGE_LIMIT = 4000
    TRACE_LIMIT = 8000
    ACTUAL_RESULT_LIMIT = 4000
    SUBSTEP_LIMIT = 50

    belongs_to :result, class_name: "TestManagement::TestResult", inverse_of: :step_results
    belongs_to :test_step, class_name: "TestManagement::TestStep", optional: true

    validates :status, inclusion: { in: STATUSES }
    validates :kind, inclusion: { in: KINDS }
    validates :match_method, inclusion: { in: MATCH_METHODS }, allow_nil: true

    scope :ordered, -> { order(:position, :id) }

    before_create { self.created_at ||= Time.current }

    def self.worst_status(statuses)
      Array(statuses).compact.min_by { |status| PRECEDENCE.index(status) || PRECEDENCE.size }
    end

    def case_step?
      kind == "case"
    end

    def reported?
      kind == "reported"
    end

    def failed?
      status == "failed"
    end

    def substeps
      Array(details_hash["substeps"])
    end

    def attachment_refs
      Array(details_hash["attachments"])
    end

    def details_hash
      (details || {}).stringify_keys
    end

    # "3" for the third case step (1-based, as shown on the case page).
    def number
      position + 1 if case_step?
    end

    def label
      step_action.presence || reported_title.presence || ""
    end
  end
end
