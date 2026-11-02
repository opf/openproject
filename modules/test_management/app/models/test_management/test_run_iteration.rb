# frozen_string_literal: true

module TestManagement
  # One execution of a test run. A run starts with iteration 1; "Start new iteration" (or a CI
  # upload in new_iteration mode) adds the next one and resets the run cases to untested.
  # Results and automation imports belong to an iteration, so earlier iterations keep their
  # counts and pass rate (history) while the run cases always reflect the current iteration.
  class TestRunIteration < ApplicationRecord
    self.table_name = "tm_test_run_iterations"

    SOURCES = %w[manual automation].freeze

    belongs_to :test_run, class_name: "TestManagement::TestRun", inverse_of: :iterations
    belongs_to :connection, class_name: "TestManagement::CiConnection", optional: true, inverse_of: :iterations
    belongs_to :created_by, class_name: "User", optional: true
    has_many :results, class_name: "TestManagement::TestResult", foreign_key: :iteration_id,
                       inverse_of: :iteration, dependent: :nullify
    has_many :automation_imports, class_name: "TestManagement::AutomationImport", foreign_key: :iteration_id,
                                  inverse_of: :iteration, dependent: :nullify

    validates :number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :test_run_id }
    validates :name, length: { maximum: 255 }
    validates :source, inclusion: { in: SOURCES }
    validates :external_ref, length: { maximum: 255 }, uniqueness: { scope: :test_run_id }, allow_nil: true

    scope :ordered, -> { order(:number) }

    def display_name
      name.presence || I18n.t("test_management.runs.iterations.default_name", number:)
    end

    def label
      name.present? ? "##{number} · #{name}" : "##{number}"
    end

    def automation?
      source == "automation"
    end

    def ci_info
      (ci_metadata || {}).stringify_keys
    end

    def current?
      test_run.iterations.maximum(:number) == number
    end

    # Status per run case inside this iteration: the latest result of the case in the
    # iteration ("untested" when the case has no result in it). Keyed by run case id.
    def run_case_statuses(run_case_ids = nil)
      run_case_ids ||= test_run.run_cases.pluck(:id)
      latest = results.where(run_case_id: run_case_ids).order(:id).pluck(:run_case_id, :status).to_h
      run_case_ids.index_with { |id| latest[id] || "untested" }
    end

    def status_counts(run_case_ids = nil)
      counts = run_case_statuses(run_case_ids).values.tally
      TestRunCase::STATUSES.index_with { |status| counts[status].to_i }
    end

    # Snapshot values set by .preload_stats for collections (API iteration list).
    attr_accessor :preloaded_status_counts, :preloaded_current

    # Status counts of several iterations in one query (latest result per case and
    # iteration), instead of two queries per iteration. Keyed by iteration id.
    def self.status_counts_for(iterations, run_case_ids)
      ids = Array(iterations).map(&:id)
      return {} if ids.empty?

      latest_ids = TestResult.where(iteration_id: ids, run_case_id: run_case_ids)
                             .group(:iteration_id, :run_case_id)
                             .select(Arel.sql("MAX(id)"))
      by_iteration = TestResult.where(id: latest_ids)
                               .pluck(:iteration_id, :run_case_id, :status)
                               .group_by(&:first)
      ids.index_with do |id|
        statuses = Array(by_iteration[id]).to_h { |_, run_case_id, status| [run_case_id, status] }
        tally = run_case_ids.map { |run_case_id| statuses[run_case_id] || "untested" }.tally
        TestRunCase::STATUSES.index_with { |status| tally[status].to_i }
      end
    end

    # Fills preloaded_current / preloaded_status_counts (the current iteration shows the
    # live run counts, past ones their own results) and preloads connections.
    def self.preload_stats(iterations, run)
      iterations = iterations.to_a
      return iterations if iterations.empty?

      current_number = run.iterations.maximum(:number)
      past = iterations.reject { |iteration| iteration.number == current_number }
      counts = status_counts_for(past, run.run_cases.pluck(:id))
      current_counts = run.status_counts
      ActiveRecord::Associations::Preloader.new(records: iterations, associations: :connection).call
      iterations.each do |iteration|
        iteration.preloaded_current = iteration.number == current_number
        iteration.preloaded_status_counts = iteration.preloaded_current ? current_counts : counts[iteration.id]
      end
    end

    def passed_percent(counts = status_counts)
      TestRun.pass_rate(counts)
    end
  end
end
