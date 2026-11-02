# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test run transitions" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:manager) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:uploader) { create(:user, member_with_permissions: { project => %i[view_test_runs upload_test_results] }) }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }
  let(:run) { create(:tm_test_run, :in_progress, project:, name: "Nightly") }
  let!(:passed) { create(:tm_test_run_case, test_run: run, status: "passed") }
  let!(:failed) { create(:tm_test_run_case, test_run: run, status: "failed") }

  describe TestManagement::TestRuns::CompleteService do
    it "completes, freezes statuses and writes case history" do
      result = described_class.new(user: manager, model: run).call

      expect(result).to be_success
      expect(run.reload).to have_attributes(state: "completed", finished_by: manager)
      expect(run.finished_at).to be_present
      expect(passed.reload.final_status).to eq("passed")
      expect(failed.reload.final_status).to eq("failed")

      event = passed.test_case.events.last
      expect(event.action).to eq("run_completed")
      expect(event.details).to eq("run_id" => run.id, "run_name" => "Nightly", "status" => "passed")
    end

    it "can be called by test automation (upload_test_results)" do
      expect(described_class.new(user: uploader, model: run).call).to be_success
    end

    it "is refused without permission" do
      result = described_class.new(user: viewer, model: run).call

      expect(result).not_to be_success
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(run.reload.state).to eq("in_progress")
    end

    it "is refused for a finished run" do
      described_class.new(user: manager, model: run).call
      result = described_class.new(user: manager, model: run.reload).call

      expect(result.errors.symbols_for(:base)).to include(:tm_invalid_transition)
    end
  end

  describe TestManagement::TestRuns::CancelService do
    it "cancels, freezes statuses and writes run_cancelled events" do
      expect(described_class.new(user: manager, model: run).call).to be_success
      expect(run.reload.state).to eq("cancelled")
      expect(failed.reload.final_status).to eq("failed")
      expect(failed.test_case.events.last.action).to eq("run_cancelled")
    end

    it "is not available to automation users" do
      expect(described_class.new(user: uploader, model: run).call).not_to be_success
    end
  end

  describe TestManagement::TestRuns::ReopenService do
    before { TestManagement::TestRuns::CompleteService.new(user: manager, model: run).call }

    it "reopens to in_progress, releases frozen statuses and keeps history" do
      events_before = TestManagement::TestCaseEvent.count
      result = described_class.new(user: manager, model: run.reload).call

      expect(result).to be_success
      expect(run.reload).to have_attributes(state: "in_progress", finished_at: nil, finished_by: nil)
      expect(passed.reload.final_status).to be_nil
      expect(TestManagement::TestCaseEvent.count).to eq(events_before)
    end

    it "adds cases created while an all-run was closed" do
      run.update_columns(selection_mode: "all")
      late = create(:tm_test_case, project:)
      described_class.new(user: manager, model: run.reload).call

      expect(run.test_cases).to include(late)
    end

    it "is refused for an active run" do
      described_class.new(user: manager, model: run.reload).call
      expect(described_class.new(user: manager, model: run.reload).call).not_to be_success
    end
  end
end
