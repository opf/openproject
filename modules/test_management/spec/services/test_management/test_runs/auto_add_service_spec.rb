# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRuns::AutoAddService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:label) { create(:tm_label, project:, name: "smoke") }
  let!(:all_run) { create(:tm_test_run, project:, selection_mode: "all") }
  let!(:dynamic_run) do
    create(:tm_test_run, project:, selection_mode: "dynamic", filter_options: { "label_ids" => [label.id] })
  end
  let!(:specific_run) { create(:tm_test_run, project:, selection_mode: "specific") }
  let!(:finished_run) { create(:tm_test_run, :completed, project:, selection_mode: "all") }

  it "adds a new case to active all-runs (via after_commit)" do
    test_case = create(:tm_test_case, project:)

    expect(all_run.test_cases).to include(test_case)
    expect(specific_run.test_cases).to be_empty
    expect(finished_run.test_cases).to be_empty
    expect(dynamic_run.test_cases).to be_empty
  end

  it "adds a case to dynamic runs once it matches" do
    test_case = create(:tm_test_case, project:)
    create(:tm_test_case_label, test_case:, label:)
    test_case.update!(title: "touched")

    expect(dynamic_run.reload.test_cases).to include(test_case)
  end

  it "does not add a case twice and ignores deleted cases" do
    test_case = create(:tm_test_case, project:)
    described_class.new(test_case).call

    expect(all_run.run_cases.where(test_case:).count).to eq(1)
    deleted = create(:tm_test_case, project:)
    all_run.run_cases.where(test_case: deleted).delete_all
    deleted.update_columns(deleted_at: Time.current)

    expect(described_class.new(deleted.reload).call).to eq([])
  end

  it "ignores other projects" do
    create(:tm_test_case)
    expect(all_run.run_cases).to be_empty
  end

  it "assigns new run cases to the run's assignee" do
    assignee = create(:user)
    all_run.update!(assigned_to: assignee)
    test_case = create(:tm_test_case, project:)

    expect(all_run.run_cases.find_by(test_case:).assigned_to).to eq(assignee)
  end
end
