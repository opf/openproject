# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management inbound-only CI connection (UI)", :skip_csrf, :webmock, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation manage_test_ci]
           })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:connection) do
    create(:tm_ci_connection, :self_hosted_gitlab, :inbound_only, project:, name: "Internal GitLab")
  end

  before { login_as(user) }

  it "prepares the run without calling the server and shows how to start the pipeline" do
    post "/projects/#{project.identifier}/test_management/ci_triggers",
         params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id, mode: "new_run", ref: "" } }

    run = TestManagement::TestRun.where(project_id: project.id).sole
    expect(response).to redirect_to("/projects/#{project.identifier}/test_management/test_runs/#{run.id}#tm-ci-manual-start")
    expect(WebMock).not_to have_requested(:any, //)

    get "/projects/#{project.identifier}/test_management/test_runs/#{run.id}"
    expect(response.body).to include("tm-ci-manual-start", "OP_RUN_ID=#{run.id}", "qa%2Fweb%2Fshop/trigger/pipeline",
                                     "$GITLAB_TRIGGER_TOKEN")
    expect(response.body).not_to include("glptt-selfhosted-secret", "glpat-selfhosted-secret")
  end

  it "shows the inbound-only badge and hides Check connection in the settings" do
    get project_test_management_project_settings_path(project)

    expect(response.body).to include("Inbound only", "https://git.example.com/gitlab")
    expect(response.body).not_to include("tm-ci-check-#{connection.id}")
  end
end
