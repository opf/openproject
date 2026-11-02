# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRuns::UpdateContract, "milestone" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs] }) }

  let(:run) { create(:tm_test_run, project:) }

  def errors_for(milestone_id)
    run.milestone_id = milestone_id
    contract = described_class.new(run, manager)
    contract.validate
    contract.errors.details[:milestone]
  end

  it "accepts an open milestone of the project and clearing it" do
    expect(errors_for(create(:tm_milestone, project:).id)).to be_empty
    expect(errors_for(nil)).to be_empty
  end

  it "rejects a foreign or completed milestone" do
    expect(errors_for(create(:tm_milestone, project: other_project).id)).to include(error: :invalid)
    expect(errors_for(create(:tm_milestone, :completed, project:).id)).to include(error: :tm_milestone_completed)
  end

  it "keeps a run editable while its milestone is completed" do
    milestone = create(:tm_milestone, project:)
    run.update!(milestone:)
    milestone.update!(status: "completed")
    run.reload.name = "Renamed"
    contract = described_class.new(run, manager)
    contract.validate
    expect(contract.errors.details[:milestone]).to be_empty
  end

  it "rejects milestones when they are disabled" do
    milestone = create(:tm_milestone, project:)
    create(:tm_project_setting, project:).update!(enable_milestones: false)
    expect(errors_for(milestone.id)).to include(error: :invalid)
  end
end
