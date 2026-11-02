# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestPlan do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  describe "validations" do
    it "requires a name" do
      plan = build(:tm_test_plan, project:, name: "")
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to be_present
    end

    it "rejects a milestone from another project" do
      other = create(:tm_milestone, project: create(:project))
      plan = build(:tm_test_plan, project:, milestone: other)
      expect(plan).not_to be_valid
      expect(plan.errors[:milestone]).to be_present
    end
  end

  describe ".preload_summaries" do
    it "aggregates case statuses from non-cancelled owned runs" do
      plan = create(:tm_test_plan, project:)
      run = create(:tm_test_run, project:, test_plan: plan)
      create(:tm_test_run_case, test_run: run, status: "passed")
      create(:tm_test_run_case, test_run: run, status: "failed")
      cancelled = create(:tm_test_run, :cancelled, project:, test_plan: plan)
      create(:tm_test_run_case, test_run: cancelled, status: "passed")

      described_class.preload_summaries([plan])
      expect(plan.runs_count).to eq(1)
      expect(plan.status_counts["passed"]).to eq(1)
      expect(plan.status_counts["failed"]).to eq(1)
      expect(plan.pass_rate).to eq(50)
    end
  end

  describe ".enabled_for?" do
    it "is true by default when the module is enabled" do
      expect(described_class.enabled_for?(project)).to be(true)
    end

    it "is false when plans are disabled in project settings" do
      create(:tm_project_setting, project:, enable_test_plans: false)
      expect(described_class.enabled_for?(project)).to be(false)
    end
  end
end
