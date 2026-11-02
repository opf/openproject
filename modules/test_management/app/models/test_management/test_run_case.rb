# frozen_string_literal: true

module TestManagement
  # A test case inside a test run, with its execution status and assignee.
  class TestRunCase < ApplicationRecord
    self.table_name = "tm_test_run_cases"

    # "skipped" comes from automation (a test skipped by the runner). It is shown
    # separately and excluded from the pass rate (see TestRun.pass_rate).
    STATUSES = %w[passed failed blocked retest in_progress skipped untested].freeze
    # Worst-first: when several reported results hit one case in an import
    # (e.g. chromium + firefox), the worst wins.
    PRECEDENCE = %w[failed blocked retest in_progress passed skipped untested].freeze

    belongs_to :test_run, class_name: "TestManagement::TestRun", inverse_of: :run_cases
    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :run_cases
    belongs_to :assigned_to, class_name: "User", optional: true

    has_many :results,
             -> { order(:created_at, :id) },
             class_name: "TestManagement::TestResult",
             foreign_key: :run_case_id,
             inverse_of: :run_case,
             dependent: :delete_all

    # Attachments (screenshots, traces, videos, reports) – uploaded manually on the
    # run page or by CI through the ingest API. OpenProject core attachments, so
    # size limits, the content-type allow list and virus scanning apply.
    acts_as_attachable view_permission: :view_test_runs,
                       add_on_new_permission: %i[execute_test_runs add_test_runs upload_test_results],
                       add_on_persisted_permission: %i[execute_test_runs add_test_runs upload_test_results],
                       delete_permission: %i[execute_test_runs add_test_runs],
                       modification_blocked: ->(*) { test_run&.finished? }

    delegate :project, to: :test_run, allow_nil: true

    validates :status, inclusion: { in: STATUSES }
    validates :final_status, inclusion: { in: STATUSES }, allow_nil: true
    validates :test_case_id, uniqueness: { scope: :test_run_id }

    # SQL for the status that counts: the frozen one when the run is finished.
    def self.effective_status_sql
      Arel.sql("COALESCE(tm_test_run_cases.final_status, tm_test_run_cases.status)")
    end

    def effective_status
      final_status.presence || status
    end

    # NB: not named `frozen?`, which ActiveRecord uses internally.
    def status_frozen?
      final_status.present? || test_run&.finished?
    end

    def last_result
      results.last
    end

    def self.worst_status(statuses)
      Array(statuses).compact.min_by { |status| PRECEDENCE.index(status) || PRECEDENCE.size }
    end

    def title
      test_case&.title
    end
  end
end
