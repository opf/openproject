# frozen_string_literal: true

module TestManagement
  # A test run executes a set of test cases of one project.
  #
  # Lifecycle (state):
  #   new ──(first case status leaves "untested")──> in_progress
  #   new / in_progress ──Complete──> completed   (statuses frozen, case history written)
  #   new / in_progress ──Cancel────> cancelled   (statuses frozen, case history written)
  #   completed / cancelled ──Reopen──> in_progress
  #
  # Case selection (selection_mode):
  #   all      – every test case of the project; new cases are added while the run is active
  #   specific – an explicit list; nothing is added automatically
  #   dynamic  – cases matching filter_options; matching new/changed cases are added while active
  class TestRun < ApplicationRecord
    self.table_name = "tm_test_runs"

    STATES = %w[new in_progress completed cancelled].freeze
    ACTIVE_STATES = %w[new in_progress].freeze
    FINISHED_STATES = %w[completed cancelled].freeze
    SELECTION_MODES = %w[all specific dynamic].freeze
    SOURCES = %w[manual automation].freeze
    AUTOMATION_FILTERS = %w[any automated manual].freeze

    belongs_to :project
    belongs_to :author, class_name: "User", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true
    belongs_to :finished_by, class_name: "User", optional: true
    belongs_to :connection, class_name: "TestManagement::CiConnection", optional: true, inverse_of: :test_runs
    belongs_to :milestone, class_name: "TestManagement::Milestone", optional: true, inverse_of: :test_runs
    belongs_to :test_plan, class_name: "TestManagement::TestPlan", optional: true, inverse_of: :test_runs
    belongs_to :test_plan_entry, class_name: "TestManagement::TestPlanEntry", optional: true, inverse_of: :test_runs

    has_many :run_cases,
             class_name: "TestManagement::TestRunCase",
             inverse_of: :test_run,
             dependent: :delete_all
    has_many :test_cases, through: :run_cases

    has_many :test_run_work_packages,
             class_name: "TestManagement::TestRunWorkPackage",
             inverse_of: :test_run,
             autosave: true,
             validate: false,
             dependent: :delete_all
    has_many :work_packages, through: :test_run_work_packages

    has_many :automation_imports,
             class_name: "TestManagement::AutomationImport",
             inverse_of: :test_run,
             dependent: :delete_all

    has_many :iterations,
             -> { order(:number) },
             class_name: "TestManagement::TestRunIteration",
             foreign_key: :test_run_id,
             inverse_of: :test_run,
             dependent: :delete_all

    # Run-level files, e.g. the CI HTML report (playwright-report.zip) or logs.
    acts_as_attachable view_permission: :view_test_runs,
                       add_on_new_permission: %i[add_test_runs upload_test_results],
                       add_on_persisted_permission: %i[add_test_runs upload_test_results],
                       delete_permission: :add_test_runs,
                       modification_blocked: ->(*) { finished? }

    # Run cases are deleted in bulk; their attachments (files) need a proper destroy.
    before_destroy :destroy_run_case_attachments, prepend: true

    # Virtual: explicit case selection submitted with the form (specific mode).
    # nil = "not submitted, keep the current cases".
    attr_accessor :selected_case_ids

    validates :name, presence: true, length: { maximum: 255 }
    validates :state, inclusion: { in: STATES }
    validates :selection_mode, inclusion: { in: SELECTION_MODES }
    validates :source, inclusion: { in: SOURCES }
    validates :completion_source, inclusion: { in: SOURCES }, allow_nil: true
    validates :external_ref, length: { maximum: 255 }, uniqueness: { scope: :project_id }, allow_nil: true
    validate :end_date_after_start_date
    validate :milestone_in_project
    validate :test_plan_in_project

    scope :active, -> { where(state: ACTIVE_STATES) }
    scope :in_state, ->(state) { where(state:) }
    scope :newest_first, -> { order(id: :desc) }

    def destroy_run_case_attachments
      ::Attachment.where(container_type: TestManagement::TestRunCase.name, container_id: run_cases.select(:id))
                  .find_each(&:destroy)
    end
    private :destroy_run_case_attachments

    def active?
      ACTIVE_STATES.include?(state)
    end

    def finished?
      FINISHED_STATES.include?(state)
    end
    alias_method :frozen_statuses?, :finished?

    def auto_adds_cases?
      active? && %w[all dynamic].include?(selection_mode)
    end

    def formatted_id
      "R#{id}"
    end

    def plan_owned?
      test_plan_id.present?
    end

    def selected_configuration_ids
      Array(configuration_ids).map(&:to_i).reject(&:zero?)
    end

    def automation?
      source == "automation"
    end

    def ci_info
      (ci_metadata || {}).stringify_keys
    end

    # Tests reported by CI that could not be matched to a case, over all imports.
    def unmatched_tests
      automation_imports.order(:id).flat_map(&:unmatched_list)
    end

    # Linked work package ids after pending (unsaved) link changes.
    def linked_work_package_ids
      test_run_work_packages.reject(&:marked_for_destruction?).map(&:work_package_id)
    end

    def work_package_links_changed?
      test_run_work_packages.any? { |link| link.new_record? || link.marked_for_destruction? }
    end

    # --- dynamic filter -------------------------------------------------------
    def filter_label_ids
      Array(filter_options&.dig("label_ids")).map(&:to_i).reject(&:zero?)
    end

    def filter_suite_ids
      Array(filter_options&.dig("suite_ids")).map(&:to_i).reject(&:zero?)
    end

    def filter_automation
      value = filter_options&.dig("automation").to_s
      AUTOMATION_FILTERS.include?(value) ? value : "any"
    end

    # Cases of the project that belong in this run according to its selection mode
    # (not used for "specific", whose list is explicit).
    def matching_cases_scope
      scope = project.tm_test_cases.not_deleted
      return scope if selection_mode == "all"
      return scope.none unless selection_mode == "dynamic"

      if filter_label_ids.any?
        scope = scope.where(id: TestCaseLabel.where(label_id: filter_label_ids).select(:test_case_id))
      end
      scope = scope.where(automated: filter_automation == "automated") unless filter_automation == "any"
      scope = scope.where(suite_id: Suite.subtree_ids(project, filter_suite_ids)) if filter_suite_ids.any?
      scope
    end

    def matches?(test_case)
      return false if test_case.deleted? || test_case.project_id != project_id
      return true if selection_mode == "all"

      matching_cases_scope.exists?(id: test_case.id)
    end

    # Add the given cases (or, for all/dynamic, every matching case) that are not yet in the run.
    def add_cases!(cases = nil)
      cases ||= matching_cases_scope
      existing = run_cases.pluck(:test_case_id)
      Array(cases.is_a?(ActiveRecord::Relation) ? cases.to_a : cases).each do |test_case|
        next if existing.include?(test_case.id)

        run_cases.create!(test_case:, assigned_to_id:, status: "untested")
        existing << test_case.id
      end
    end

    # --- iterations -----------------------------------------------------------
    # nil for runs that were never iterated and have no results yet (they get iteration 1
    # lazily, see TestRunIterations::Starter).
    def current_iteration
      iterations.reorder(number: :desc).first
    end

    def current_iteration_number
      return @preloaded_stats[:current_iteration_number] if @preloaded_stats

      iterations.maximum(:number)
    end

    def iterations_count
      return @preloaded_stats[:iterations_count] if @preloaded_stats

      iterations.count
    end

    def iteration(number)
      iterations.find_by(number: number.to_i)
    end

    # --- statistics -----------------------------------------------------------
    def status_counts
      return @preloaded_stats[:status_counts] if @preloaded_stats

      counts = run_cases.group(TestRunCase.effective_status_sql).count
      TestRunCase::STATUSES.index_with { |status| counts[status].to_i }
    end

    # Number of CI tests that matched no case, over all imports (the stored lists are
    # capped at 1000 entries per import; the counter is not).
    def unmatched_tests_count
      return @preloaded_stats[:unmatched_tests_count] if @preloaded_stats

      automation_imports.sum(:unmatched_count)
    end

    # Collections (API run list): status counts, iteration numbers and unmatched counts
    # for all runs in three grouped queries instead of four or more queries per run.
    # The values are a snapshot; #reload drops them.
    def self.preload_stats(runs)
      runs = runs.to_a
      ids = runs.map(&:id)
      return runs if ids.empty?

      counts = TestRunCase.where(test_run_id: ids).group(:test_run_id, TestRunCase.effective_status_sql).count
      iterations = TestRunIteration.where(test_run_id: ids).group(:test_run_id)
                                   .pluck(:test_run_id, Arel.sql("MAX(number)"), Arel.sql("COUNT(*)"))
                                   .to_h { |id, max, count| [id, [max, count]] }
      unmatched = AutomationImport.where(test_run_id: ids).group(:test_run_id).sum(:unmatched_count)
      ActiveRecord::Associations::Preloader.new(records: runs, associations: :connection).call
      runs.each do |run|
        run.preloaded_stats = {
          status_counts: TestRunCase::STATUSES.index_with { |status| counts[[run.id, status]].to_i },
          current_iteration_number: iterations.dig(run.id, 0),
          iterations_count: iterations.dig(run.id, 1).to_i,
          unmatched_tests_count: unmatched[run.id].to_i
        }
      end
    end

    attr_writer :preloaded_stats

    def reload(*)
      @preloaded_stats = nil
      super
    end

    def total_cases
      status_counts.values.sum
    end

    # Pass rate: passed / executable cases. Skipped cases are reported separately and
    # do not count towards the denominator.
    def passed_percent(counts = status_counts)
      self.class.pass_rate(counts)
    end

    def self.pass_rate(counts)
      total = counts.values.sum - counts["skipped"].to_i
      return 0 if total <= 0

      ((counts["passed"].to_f / total) * 100).round
    end

    private

    def milestone_in_project
      return if milestone_id.blank?

      errors.add :milestone, :invalid if milestone.nil? || milestone.project_id != project_id
    end

    def test_plan_in_project
      return if test_plan_id.blank?

      errors.add :test_plan, :invalid if test_plan.nil? || test_plan.project_id != project_id
    end

    def end_date_after_start_date
      return if start_date.blank? || end_date.blank? || end_date >= start_date

      errors.add :end_date, :greater_than_or_equal_to, count: I18n.l(start_date)
    end
  end
end
