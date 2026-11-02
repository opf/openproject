# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::CiTriggers::TriggerContract, "milestone" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds an item") }
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

  def milestone_errors(milestone, **attributes)
    request = TestManagement::CiTriggers::Request.new(project:, connection:, suite:, milestone:, **attributes)
    described_class.new(request, trigger_user).validate
    request.errors.details[:milestone]
  end

  it "accepts an open milestone of the project for a new run" do
    expect(milestone_errors(create(:tm_milestone, project:))).to be_empty
    expect(milestone_errors(nil)).to be_empty
  end

  it "rejects a foreign, completed or disabled milestone" do
    expect(milestone_errors(create(:tm_milestone, project: other_project))).to include(error: :invalid)
    expect(milestone_errors(create(:tm_milestone, :completed, project:))).to include(error: :tm_milestone_completed)

    open_one = create(:tm_milestone, project:)
    create(:tm_project_setting, project:).update!(enable_milestones: false)
    expect(milestone_errors(open_one)).to include(error: :invalid)
  end

  it "only allows a milestone for a new run" do
    run = create(:tm_test_run, :in_progress, project:)
    errors = milestone_errors(create(:tm_milestone, project:), mode: "new_iteration", run:, suite: nil)
    expect(errors).to include(error: :tm_ci_milestone_new_run_only)
  end
end
