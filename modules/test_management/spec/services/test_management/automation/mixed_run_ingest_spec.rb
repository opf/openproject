# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::IngestService, "mixed manual/automated run" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs upload_test_results]
           })
  end

  let(:automated) do
    create(:tm_test_case, project:, title: "signs in", automated: true,
                          automation_reference: "tests/login.spec.ts#signs in")
  end
  let(:manual) { create(:tm_test_case, project:, title: "Manual check", automated: false) }
  let(:run) { create(:tm_test_run, :in_progress, project:, selection_mode: "specific") }
  let(:report) do
    { tests: [{ reference: automated.automation_reference, title: "signs in", status: "passed" }] }.to_json
  end

  before do
    create(:tm_test_run_case, test_run: run, test_case: automated, status: "untested")
    create(:tm_test_run_case, test_run: run, test_case: manual, status: "passed")
  end

  def ingest(**options)
    described_class.new(user:, project:)
                   .call(content: report, options: options.deep_stringify_keys.merge("format" => "native", "runId" => run.id))
  end

  it "updates only matched automated cases and leaves manual statuses untouched" do
    outcome = ingest
    expect(outcome.run.id).to eq(run.id)

    expect(run.run_cases.find_by(test_case_id: automated.id).reload.status).to eq("passed")
    expect(run.run_cases.find_by(test_case_id: manual.id).reload.status).to eq("passed")
    expect(run.reload.state).to eq("in_progress")
  end

  it "can create, fill and close a standalone run via CI" do
    content = { tests: [{ caseId: automated.id, status: "passed" }] }.to_json
    outcome = described_class.new(user:, project:)
                             .call(content:, options: { "format" => "native", "externalRef" => "ci:create-close",
                                                        "closeRun" => true })

    expect(outcome.run).to be_persisted
    expect(outcome.run.state).to eq("completed")
    expect(outcome.run.milestone_id).to be_nil
  end

  it "assigns a milestone when creating a CI-owned run" do
    milestone = create(:tm_milestone, project:, name: "Release CI")
    content = { tests: [{ caseId: automated.id, status: "passed" }] }.to_json
    outcome = described_class.new(user:, project:)
                             .call(content:,
                                   options: { "format" => "native", "externalRef" => "ci:ms", "milestone" => milestone.name })

    expect(outcome.run.milestone).to eq(milestone)
  end
end
