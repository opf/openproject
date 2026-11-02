# frozen_string_literal: true

module TestManagement
  # Optional campaign that groups and spawns test runs (optionally a configuration matrix).
  # Standalone runs remain first-class; a plan is additive.
  #
  # State: active ──Complete──> completed ──Reopen──> active
  class TestPlan < ApplicationRecord
    self.table_name = "tm_test_plans"

    STATES = %w[active completed].freeze
    ACTIVE_STATES = %w[active].freeze

    belongs_to :project
    belongs_to :milestone, class_name: "TestManagement::Milestone", optional: true, inverse_of: :test_plans
    belongs_to :author, class_name: "User", optional: true
    belongs_to :assigned_to, class_name: "User", optional: true
    belongs_to :finished_by, class_name: "User", optional: true

    has_many :entries,
             -> { order(:position, :id) },
             class_name: "TestManagement::TestPlanEntry",
             foreign_key: :test_plan_id,
             inverse_of: :test_plan,
             dependent: :destroy
    has_many :test_runs,
             class_name: "TestManagement::TestRun",
             inverse_of: :test_plan,
             dependent: :nullify
    has_many :test_plan_work_packages,
             class_name: "TestManagement::TestPlanWorkPackage",
             inverse_of: :test_plan,
             autosave: true,
             validate: false,
             dependent: :delete_all
    has_many :work_packages, through: :test_plan_work_packages

    validates :name, presence: true, length: { maximum: 255 }
    validates :state, inclusion: { in: STATES }
    validate :end_date_after_start_date
    validate :milestone_in_project

    scope :active, -> { where(state: ACTIVE_STATES) }
    scope :completed, -> { where(state: "completed") }
    scope :newest_first, -> { order(id: :desc) }
    scope :ordered, -> { order(Arel.sql("tm_test_plans.end_date IS NULL, tm_test_plans.end_date, tm_test_plans.id")) }

    scope :visible, ->(user = User.current) {
      where(project_id: Project.allowed_to(user, :view_test_plans).select(:id))
        .where.not(project_id: ProjectSetting.plans_disabled_project_ids)
    }

    def self.enabled_for?(project)
      project.present? && project.module_enabled?(:test_management) && ProjectSetting.plans_enabled?(project)
    end

    def formatted_id
      "P#{id}"
    end

    def active?
      state == "active"
    end

    def completed?
      state == "completed"
    end
    alias_method :finished?, :completed?

    def linked_work_package_ids
      test_plan_work_packages.reject(&:marked_for_destruction?).map(&:work_package_id)
    end

    def status_counts
      return @preloaded_summary[:status_counts] if @preloaded_summary

      TestPlan.preload_summaries([self])
      @preloaded_summary[:status_counts]
    end

    def runs_count
      status_counts && @preloaded_summary[:runs_count]
    end

    def total_cases
      status_counts.values.sum
    end

    def pass_rate
      TestRun.pass_rate(status_counts)
    end

    attr_writer :preloaded_summary

    def reload(*)
      @preloaded_summary = nil
      super
    end

    def self.preload_summaries(plans)
      plans = plans.to_a
      run_ids_by_plan = TestRun.where(test_plan_id: plans.map(&:id))
                               .where.not(state: "cancelled")
                               .pluck(:id, :test_plan_id)
                               .group_by(&:last)
                               .transform_values { |pairs| pairs.map(&:first) }
      all_run_ids = run_ids_by_plan.values.flatten
      counts = if all_run_ids.empty?
                 {}
               else
                 TestRunCase.where(test_run_id: all_run_ids).group(:test_run_id, TestRunCase.effective_status_sql).count
               end
      plans.each do |plan|
        run_ids = run_ids_by_plan.fetch(plan.id, [])
        status_counts = TestRunCase::STATUSES.index_with do |status|
          run_ids.sum { |run_id| counts[[run_id, status]].to_i }
        end
        plan.preloaded_summary = { status_counts:, runs_count: run_ids.size }
      end
      plans
    end

    private

    def end_date_after_start_date
      return if start_date.blank? || end_date.blank? || end_date >= start_date

      errors.add :end_date, :greater_than_or_equal_to, count: I18n.l(start_date)
    end

    def milestone_in_project
      return if milestone_id.blank?
      return if milestone&.project_id == project_id

      errors.add :milestone, :invalid
    end
  end
end
