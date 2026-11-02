# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Milestone do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }

  def run_with(milestone, *statuses, state: "in_progress")
    run = create(:tm_test_run, project: milestone.project, milestone:, state:,
                               finished_at: (%w[completed cancelled].include?(state) ? Time.current : nil))
    statuses.each { |status| create(:tm_test_run_case, test_run: run, status:) }
    run
  end

  describe "validations" do
    it "needs a name and a known status" do
      milestone = build(:tm_milestone, project:, name: "", status: "paused")
      expect(milestone).not_to be_valid
      expect(milestone.errors.attribute_names).to include(:name, :status)
    end

    it "rejects a due date before the start date" do
      milestone = build(:tm_milestone, project:, start_date: Date.new(2026, 11, 10), due_date: Date.new(2026, 11, 1))
      expect(milestone).not_to be_valid
      expect(milestone.errors.details[:due_date]).to include(a_hash_including(error: :greater_than_or_equal_to))
    end

    it "allows one level of sub-milestones in the same project" do
      release = create(:tm_milestone, project:, name: "Release 2.0")
      sprint = create(:tm_milestone, project:, parent: release, name: "Sprint 14")
      expect(sprint).to be_sub_milestone

      expect(build(:tm_milestone, project:, parent: sprint)).not_to be_valid
      expect(build(:tm_milestone, project: other_project, parent: release)).not_to be_valid

      release.parent = create(:tm_milestone, project:)
      expect(release).not_to be_valid
      expect(release.errors.details[:parent]).to include(error: :tm_milestone_has_children)
    end
  end

  describe ".lookup" do
    let!(:open_one) { create(:tm_milestone, project:, name: "Release 2.0") }
    let!(:done_one) { create(:tm_milestone, :completed, project:, name: "release 2.0") }

    it "finds by id, by M-id and by name (case-insensitive, open ones first)" do
      expect(described_class.lookup(project, open_one.id.to_s)).to eq(open_one)
      expect(described_class.lookup(project, "M#{done_one.id}")).to eq(done_one)
      expect(described_class.lookup(project, "RELEASE 2.0")).to eq(open_one)
      expect(described_class.lookup(project, "  ")).to be_nil
      expect(described_class.lookup(other_project, open_one.id.to_s)).to be_nil
    end
  end

  describe "status helpers" do
    it "is overdue only while not completed and past the due date" do
      expect(build(:tm_milestone, :overdue)).to be_overdue
      expect(build(:tm_milestone, :overdue, :completed)).not_to be_overdue
      expect(build(:tm_milestone, due_date: Date.current)).not_to be_overdue
      expect(build(:tm_milestone, :completed)).not_to be_assignable
    end
  end

  describe "progress" do
    let(:release) { create(:tm_milestone, project:, name: "Release 2.0") }
    let(:sprint) { create(:tm_milestone, project:, parent: release, name: "Sprint 14") }

    before do
      run_with(release, "passed", "passed", "failed", "skipped")
      run_with(sprint, "passed", "blocked")
      run_with(release, "failed", "failed", state: "cancelled")
    end

    it "rolls sub-milestone runs up into the parent and excludes cancelled runs" do
      expect(release.runs_count).to eq(2)
      expect(release.total_cases).to eq(6)
      expect(release.status_counts).to include("passed" => 3, "failed" => 1, "blocked" => 1, "skipped" => 1)
      # passed / (total - skipped) = 3 / 5
      expect(release.pass_rate).to eq(60)
      expect(sprint.reload.total_cases).to eq(2)
    end

    it "preloads parent and child together without losing the child's runs" do
      described_class.preload_summaries([release, sprint])
      expect(release.runs_count).to eq(2)
      expect(sprint.runs_count).to eq(1)
      expect(sprint.status_counts).to include("passed" => 1, "blocked" => 1)
    end
  end

  describe "deletion" do
    it "keeps the runs (unassigned) and makes sub-milestones top-level" do
      release = create(:tm_milestone, project:)
      sprint = create(:tm_milestone, project:, parent: release)
      run = create(:tm_test_run, project:, milestone: release)

      release.destroy!

      expect(run.reload.milestone_id).to be_nil
      expect(sprint.reload.parent_id).to be_nil
    end
  end

  describe ".visible" do
    shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
    shared_let(:cases_only) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

    it "needs view_test_runs and milestones enabled" do
      milestone = create(:tm_milestone, project:)
      expect(described_class.visible(viewer)).to include(milestone)
      expect(described_class.visible(cases_only)).not_to include(milestone)

      create(:tm_project_setting, project:).update!(enable_milestones: false)
      expect(described_class.visible(viewer)).not_to include(milestone)
    end
  end
end
