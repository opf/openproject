# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRunCase do
  let(:run_case) { create(:tm_test_run_case) }

  it "validates the status" do
    run_case.status = "bogus"
    expect(run_case).not_to be_valid
  end

  it "is unique per run and case" do
    duplicate = described_class.new(test_run: run_case.test_run, test_case: run_case.test_case)
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "uses the frozen status once the run is finished" do
    run_case.update!(status: "passed")
    expect(run_case.effective_status).to eq("passed")

    run_case.update_columns(final_status: "failed")
    expect(run_case.reload.effective_status).to eq("failed")
  end

  it "is frozen when its run is finished" do
    expect(run_case).not_to be_status_frozen
    run_case.test_run.update!(state: "completed")
    expect(run_case.reload).to be_status_frozen
    expect(run_case).not_to be_frozen # ActiveRecord's own frozen? is untouched
  end

  it "returns the latest result" do
    create(:tm_test_result, run_case:, status: "failed")
    latest = create(:tm_test_result, run_case:, status: "passed")

    expect(run_case.last_result).to eq(latest)
  end

  it "is removed with its run and with its test case" do
    other = create(:tm_test_run_case)
    run_case.test_run.destroy
    other.test_case.destroy

    expect(described_class.where(id: [run_case.id, other.id])).to be_empty
  end
end
