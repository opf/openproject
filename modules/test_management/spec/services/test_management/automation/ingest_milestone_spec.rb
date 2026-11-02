# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::IngestService, "milestone option" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_runs upload_test_results] }) }
  shared_let(:case_a) { create(:tm_test_case, project:, title: "Checkout") }

  let(:report) { { tests: [{ caseId: case_a.id, status: "passed" }] }.to_json }

  def ingest(**options)
    described_class.new(user:, project:)
                   .call(content: report, options: options.deep_stringify_keys.merge("format" => "native"))
  end

  def warning_codes(outcome) = Array(outcome.import.warnings).pluck("code")

  it "assigns a new run to the milestone given by name or M-id" do
    milestone = create(:tm_milestone, project:, name: "Release 2.0")

    expect(ingest(externalRef: "ci:1", milestone: "release 2.0").run.milestone).to eq(milestone)
    expect(ingest(externalRef: "ci:2", milestone: "M#{milestone.id}").run.milestone).to eq(milestone)
  end

  it "goes on with a warning for an unknown or completed milestone" do
    create(:tm_milestone, :completed, project:, name: "Release 1.9")

    unknown = ingest(externalRef: "ci:3", milestone: "Nope")
    expect(unknown.run.milestone).to be_nil
    expect(warning_codes(unknown)).to include("milestone_not_found")

    completed = ingest(externalRef: "ci:4", milestone: "Release 1.9")
    expect(completed.run.milestone).to be_nil
    expect(warning_codes(completed)).to include("milestone_completed")
  end

  it "warns when milestones are disabled" do
    create(:tm_milestone, project:, name: "Release 2.0")
    create(:tm_project_setting, project:).update!(enable_milestones: false)

    outcome = ingest(externalRef: "ci:5", milestone: "Release 2.0")
    expect(outcome.run.milestone).to be_nil
    expect(warning_codes(outcome)).to include("milestones_disabled")
  end
end
