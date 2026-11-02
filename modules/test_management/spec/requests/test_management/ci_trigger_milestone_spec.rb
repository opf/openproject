# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management Run in CI milestone (UI)", :disable_ssrf_filter, :skip_csrf, :webmock, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:, name: "E2E") }
  shared_let(:milestone) { create(:tm_milestone, project:, name: "Release 2.0") }
  shared_let(:done) { create(:tm_milestone, :completed, project:, name: "Release 1.9") }

  let(:triggers_path) { "/projects/#{project.identifier}/test_management/ci_triggers" }

  before do
    login_as(trigger_user)
    stub_request(:post, "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches").to_return(status: 204)
  end

  it "offers open milestones only" do
    get "#{triggers_path}/new", params: { suite_id: suite.id }

    expect(response.body).to include("tm-ci-trigger-milestone-field", "Release 2.0")
    expect(response.body).not_to include("Release 1.9")
  end

  it "preselects the milestone of the run when adding to a run" do
    run = create(:tm_test_run, :in_progress, project:, milestone:)
    get "#{triggers_path}/new", params: { run_id: run.id }

    expect(response.body).to match(/selected="selected" value="#{milestone.id}"/)
  end

  it "hides the field when milestones are disabled" do
    create(:tm_project_setting, project:).update!(enable_milestones: false)
    get "#{triggers_path}/new", params: { suite_id: suite.id }

    expect(response.body).not_to include("tm-ci-trigger-milestone-field")
  end

  it "assigns the new run to the chosen milestone" do
    post triggers_path, params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id, mode: "new_run",
                                                milestone_id: milestone.id } }

    expect(TestManagement::TestRun.where(project_id: project.id).sole.milestone).to eq(milestone)
  end

  it "re-renders the form for a completed or unknown milestone" do
    [done.id, 0].each do |id|
      post triggers_path,
           params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id, mode: "new_run", milestone_id: id } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
  end
end
