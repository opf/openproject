# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::RunCases::UpdateService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:tester) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_runs] }) }
  let(:run) { create(:tm_test_run, project:) }
  let(:run_case) { create(:tm_test_run_case, test_run: run) }

  # `update(status: "x")` passes keywords in Ruby 3, so collect them explicitly.
  def update(params = nil, user: tester, **attributes)
    described_class.new(user:, model: run_case).call(params || attributes)
  end

  it "changes the status, writes a result and starts the run" do
    result = update(status: "failed", comment: "500 on submit")

    expect(result).to be_success
    expect(run_case.reload.status).to eq("failed")
    expect(run_case.results.last).to have_attributes(status: "failed", comment: "500 on submit", user: tester)
    expect(run.reload.state).to eq("in_progress")
  end

  it "keeps a new run new when the status stays untested" do
    update(status: "untested")
    expect(run.reload.state).to eq("new")
    expect(run_case.results).to be_empty
  end

  it "writes a result for a comment without a status change" do
    update(status: "untested", comment: "waiting for env")
    expect(run_case.results.last.comment).to eq("waiting for env")
  end

  it "changes the assignee to a project member and can unassign" do
    expect(update(assigned_to_id: tester.id.to_s)).to be_success
    expect(run_case.reload.assigned_to).to eq(tester)

    expect(update(assigned_to_id: "")).to be_success
    expect(run_case.reload.assigned_to).to be_nil
  end

  it "rejects non-member assignees" do
    result = update(assigned_to_id: create(:user).id.to_s)
    expect(result.errors.symbols_for(:base)).to include(:tm_invalid_assignee)
  end

  it "rejects unknown statuses" do
    result = update(status: "maybe")
    expect(result.errors.symbols_for(:base)).to include(:tm_invalid_status)
  end

  it "rejects users without execute permission" do
    result = update({ status: "passed" }, user: viewer)
    expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
  end

  it "rejects changes in a finished run" do
    run.update!(state: "completed")
    result = update(status: "passed")

    expect(result.errors.symbols_for(:base)).to include(:tm_run_finished)
    expect(run_case.reload.status).to eq("untested")
  end

  describe "step results (0020)" do
    let(:test_case) { run_case.test_case }
    let!(:steps) { Array.new(3) { |i| create(:tm_test_step, test_case:, position: i, action: "Step #{i + 1}") } }

    it "stores a row per case step and derives the failed status" do
      result = update(step_results: { steps.first.id.to_s => { status: "passed" },
                                      steps.second.id.to_s => { status: "failed", actual_result: "Error <b>500</b>" } },
                      comment: "Tried twice")

      expect(result).to be_success
      expect(run_case.reload.status).to eq("failed")
      rows = run_case.results.last.step_results
      expect(rows.map(&:status)).to eq(%w[passed failed untested])
      expect(rows.map(&:test_step_id)).to eq(steps.map(&:id))
      expect(rows.second.actual_result).to eq("Error <b>500</b>")
      expect(rows.map(&:match_method).uniq).to eq(["manual"])
      expect(run_case.results.last.comment).to eq("Tried twice")
    end

    it "derives passed when every step passed and in progress for a partial run" do
      update(step_results: steps.map { |step| { test_step_id: step.id, status: "passed" } })
      expect(run_case.reload.status).to eq("passed")

      update(step_results: [{ test_step_id: steps.first.id, status: "passed" }])
      expect(run_case.reload.status).to eq("in_progress")
    end

    it "keeps an explicit status and stores a capped error message" do
      update(status: "blocked", error_message: "x" * 5000, step_results: [{ test_step_id: steps.first.id, status: "failed" }])

      expect(run_case.reload.status).to eq("blocked")
      expect(run_case.results.last.error_message.size).to eq(TestManagement::TestResult::ERROR_MESSAGE_LIMIT)
    end

    it "rejects steps of another case and unknown step statuses" do
      other = create(:tm_test_step)

      expect(update(step_results: [{ test_step_id: other.id, status: "passed" }]).errors.symbols_for(:base))
        .to include(:tm_invalid_step_result)
      expect(update(step_results: [{ test_step_id: steps.first.id, status: "great" }]).errors.symbols_for(:base))
        .to include(:tm_invalid_step_result)
      expect(run_case.results).to be_empty
    end
  end
end
