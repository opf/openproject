# frozen_string_literal: true

module TestManagement
  # A milestone groups test runs towards a goal: a release, a sprint, a regression or smoke
  # cycle, a hotfix, UAT, a beta wave, a compliance campaign … (see docs in the README).
  #
  # Hierarchy: one level of sub-milestones (a sprint under a release). A parent's progress
  # includes the runs of its sub-milestones.
  #
  # Status:
  #   open ──Start──> started ──Complete──> completed ──Reopen──> started (or open if never started)
  #   open ──Complete──> completed
  # Dates are plans only; the status never changes because of them. "Overdue" = due date
  # passed and not completed.
  #
  # Progress (status counts, pass rate): the current (latest) status of every case in every
  # non-cancelled run assigned to the milestone or one of its sub-milestones. Pass rate =
  # passed / (total − skipped), as on run pages.
  class Milestone < ApplicationRecord
    self.table_name = "tm_milestones"

    STATUSES = %w[open started completed].freeze
    COUNTED_RUN_STATES = %w[new in_progress completed].freeze

    belongs_to :project
    belongs_to :parent, class_name: "TestManagement::Milestone", optional: true, inverse_of: :children
    belongs_to :version, optional: true
    belongs_to :created_by, class_name: "User", optional: true

    has_many :children,
             -> { order(:id) },
             class_name: "TestManagement::Milestone",
             foreign_key: :parent_id,
             inverse_of: :parent,
             dependent: :nullify
    has_many :test_runs,
             class_name: "TestManagement::TestRun",
             inverse_of: :milestone,
             dependent: :nullify
    has_many :test_plans,
             class_name: "TestManagement::TestPlan",
             inverse_of: :milestone,
             dependent: :nullify
    has_many :milestone_work_packages,
             class_name: "TestManagement::MilestoneWorkPackage",
             inverse_of: :milestone,
             autosave: true,
             validate: false,
             dependent: :delete_all
    has_many :work_packages, through: :milestone_work_packages

    validates :name, presence: true, length: { maximum: 255 }
    validates :status, inclusion: { in: STATUSES }
    validate :due_date_after_start_date
    validate :parent_is_valid

    scope :ordered, -> { order(Arel.sql("tm_milestones.due_date IS NULL, tm_milestones.due_date, tm_milestones.id")) }
    scope :roots, -> { where(parent_id: nil) }
    scope :not_completed, -> { where.not(status: "completed") }
    scope :completed, -> { where(status: "completed") }

    # Milestones the user may see: :view_test_runs in the milestone's project, module and
    # milestones enabled there.
    scope :visible, ->(user = User.current) {
      where(project_id: Project.allowed_to(user, :view_test_runs).select(:id))
        .where.not(project_id: ProjectSetting.milestones_disabled_project_ids)
    }

    # Looks a milestone of the project up by id ("12"), formatted id ("M12") or name
    # (case-insensitive; open ones win over completed ones). Used by CI ingest and Run in CI.
    def self.lookup(project, ref)
      ref = ref.to_s.strip
      return nil if project.nil? || ref.empty?

      milestones = where(project_id: project.id)
      id = ref[/\A[Mm]?(\d+)\z/, 1]
      (id && milestones.find_by(id: id.to_i)) ||
        milestones.where("LOWER(tm_milestones.name) = ?", ref.downcase)
                  .order(Arel.sql("tm_milestones.status = 'completed'"), :id).first
    end

    def self.enabled_for?(project)
      project.present? && project.module_enabled?(:test_management) && ProjectSetting.milestones_enabled?(project)
    end

    def formatted_id
      "M#{id}"
    end

    def completed?
      status == "completed"
    end

    def started?
      status == "started"
    end

    def overdue?(today = Date.current)
      !completed? && due_date.present? && due_date < today
    end

    # Usable as a target for new runs (the selectors only offer these).
    def assignable?
      !completed?
    end

    def sub_milestone?
      parent_id.present?
    end

    # Linked work package ids after pending (unsaved) link changes.
    def linked_work_package_ids
      milestone_work_packages.reject(&:marked_for_destruction?).map(&:work_package_id)
    end

    # --- progress -------------------------------------------------------------
    def counted_run_ids
      Milestone.counted_runs_for([self]).fetch(id, [])
    end

    def status_counts
      return @preloaded_summary[:status_counts] if @preloaded_summary

      Milestone.preload_summaries([self])
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

    # { milestone_id => [run ids] } – own runs plus the runs of direct sub-milestones,
    # cancelled runs excluded.
    def self.counted_runs_for(milestones)
      ids = milestones.map(&:id)
      return {} if ids.empty?

      # A sub-milestone may be in the list together with its parent (index, detail page):
      # its runs then count for both.
      child_ids = where(parent_id: ids).pluck(:id, :parent_id)
                    .group_by(&:last).transform_values { |pairs| pairs.map(&:first) }
      run_ids_by_milestone = TestRun.where(milestone_id: ids | child_ids.values.flatten, state: COUNTED_RUN_STATES)
                                    .pluck(:id, :milestone_id)
                                    .group_by(&:last).transform_values { |pairs| pairs.map(&:first) }
      ids.index_with do |id|
        ([id] + child_ids.fetch(id, [])).flat_map { |owner| run_ids_by_milestone.fetch(owner, []) }.uniq
      end
    end

    # Status counts, pass rate and run count for many milestones in two queries.
    def self.preload_summaries(milestones)
      milestones = milestones.to_a
      runs_by_milestone = counted_runs_for(milestones)
      all_run_ids = runs_by_milestone.values.flatten.uniq
      counts = if all_run_ids.empty?
                 {}
               else
                 TestRunCase.where(test_run_id: all_run_ids).group(:test_run_id, TestRunCase.effective_status_sql).count
               end
      milestones.each do |milestone|
        run_ids = runs_by_milestone.fetch(milestone.id, [])
        status_counts = TestRunCase::STATUSES.index_with do |status|
          run_ids.sum { |run_id| counts[[run_id, status]].to_i }
        end
        milestone.preloaded_summary = { status_counts:, runs_count: run_ids.size }
      end
      milestones
    end

    private

    def due_date_after_start_date
      return if start_date.blank? || due_date.blank? || due_date >= start_date

      errors.add :due_date, :greater_than_or_equal_to, count: I18n.l(start_date)
    end

    # One level only, same project, not itself; a milestone with sub-milestones cannot
    # become a sub-milestone.
    def parent_is_valid
      return if parent_id.blank?

      if parent.nil? || parent.project_id != project_id || parent_id == id || parent.parent_id.present?
        errors.add :parent, :invalid
      elsif persisted? && children.exists?
        errors.add :parent, :tm_milestone_has_children
      end
    end
  end
end
