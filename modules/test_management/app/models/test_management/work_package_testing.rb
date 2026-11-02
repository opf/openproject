# frozen_string_literal: true

module TestManagement
  # What the work package "Testing" tab shows: the linked test cases, the runs of those
  # cases / runs referencing the work package, and the milestones linked to it.
  #
  # Only cases the user may see (not deleted, :view_test_cases in the case's
  # project) are returned. The latest run status is only shown where the user
  # may also see test runs (:view_test_runs).
  #
  # Milestones (0012) are listed only when the work package is linked to them: directly
  # (milestone references) or through its Version when the milestone is tied to that
  # Version. They need :view_test_runs and milestones enabled in the milestone's project.
  class WorkPackageTesting
    VIEWS = %w[milestones runs cases].freeze
    RUNS_LIMIT = 20

    attr_reader :work_package, :user

    def initialize(work_package, user: User.current)
      @work_package = work_package
      @user = user
    end

    def self.count_for(work_package, user: User.current)
      new(work_package, user:).scope.count
    end

    def scope
      TestCase
        .visible(user)
        .where(id: TestCaseWorkPackage.where(work_package_id: work_package.id).select(:test_case_id))
    end

    def test_cases
      @test_cases ||= scope.includes(:suite).order(:id).to_a
    end

    def count
      test_cases.size
    end

    # { test_case_id => latest TestRunCase } for the cases whose runs the user may see.
    def latest_run_cases
      @latest_run_cases ||= begin
        ids = test_cases.select { |tc| runs_visible?(tc.project) }.map(&:id)
        if ids.empty?
          {}
        else
          TestRunCase
            .where(test_case_id: ids)
            .includes(:test_run)
            .order(:test_case_id, id: :desc)
            .each_with_object({}) { |rc, h| h[rc.test_case_id] ||= rc }
        end
      end
    end

    # Latest result of each latest run case (0020: "Failed at step 3: …" on the case cards).
    def latest_results
      @latest_results ||= TestResult.latest_by_run_case(latest_run_cases.values.map(&:id))
    end

    # --- milestones ---------------------------------------------------------------
    def milestones
      @milestones ||= begin
        linked = MilestoneWorkPackage.where(work_package_id: work_package.id).select(:milestone_id)
        scope = Milestone.visible(user).where(id: linked)
        if work_package.respond_to?(:version_id) && work_package.version_id.present?
          scope = scope.or(Milestone.visible(user).where(version_id: work_package.version_id))
        end
        Milestone.preload_summaries(scope.includes(:project, :parent).ordered.to_a)
      end
    end

    def milestones?
      milestones.any?
    end

    # How the milestone is linked: :direct (reference) or :version.
    def milestone_link_kind(milestone)
      @direct_milestone_ids ||= MilestoneWorkPackage.where(work_package_id: work_package.id).pluck(:milestone_id).to_set
      @direct_milestone_ids.include?(milestone.id) ? :direct : :version
    end

    # --- runs ---------------------------------------------------------------------
    # Runs (newest first) that reference the work package or contain one of its visible
    # linked cases, in projects where the user may view runs.
    def runs
      @runs ||= begin
        via_cases = TestRunCase.where(test_case_id: test_cases.map(&:id)).select(:test_run_id)
        via_refs = TestRunWorkPackage.where(work_package_id: work_package.id).select(:test_run_id)
        TestRun
          .where(id: via_cases).or(TestRun.where(id: via_refs))
          .where(project_id: Project.allowed_to(user, :view_test_runs).select(:id))
          .includes(:project, :milestone)
          .newest_first
          .limit(RUNS_LIMIT)
          .to_a
      end
    end

    def run_status_counts
      @run_status_counts ||= begin
        ids = runs.map(&:id)
        raw = TestRunCase.where(test_run_id: ids).group(:test_run_id, TestRunCase.effective_status_sql).count
        ids.index_with { |id| TestRunCase::STATUSES.index_with { |status| raw[[id, status]].to_i } }
      end
    end

    # Segments of the tab's view switcher; "milestones" only when milestones are linked.
    def views
      milestones? ? VIEWS : VIEWS - %w[milestones]
    end

    def default_view
      milestones? ? "milestones" : "cases"
    end

    def view_for(requested)
      views.include?(requested.to_s) ? requested.to_s : default_view
    end

    def can_link?
      user.allowed_in_project?(:link_test_cases_to_work_packages, work_package.project)
    end

    private

    def runs_visible?(project)
      @runs_visible ||= {}
      @runs_visible.fetch(project.id) { @runs_visible[project.id] = user.allowed_in_project?(:view_test_runs, project) }
    end
  end
end
