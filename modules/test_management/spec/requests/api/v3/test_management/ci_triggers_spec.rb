# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management Run in CI", :disable_ssrf_filter, :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, identifier: "shop-api", enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:runner) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs] }) }
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/a.spec.ts#pays") }
  shared_let(:connection) do
    create(:tm_ci_connection, :gitlab_trigger, project:, name: "Pipelines", base_url: "https://gitlab.example.com")
  end

  let(:path) { api_v3_paths.project_test_management_ci_triggers(project.id) }
  let(:pipeline_url) { "https://gitlab.example.com/api/v4/projects/group%2Fsub%2Fapp/trigger/pipeline" }

  before { login_as(trigger_user) }

  def json = JSON.parse(last_response.body)

  def post_json(body)
    post path, body.to_json, { "CONTENT_TYPE" => "application/json" }
  end

  it "pre-creates the run, triggers the pipeline and answers 201" do
    stub_request(:post, pipeline_url).to_return(status: 201, body: { id: 77, web_url: "https://gitlab.example.com/p/77" }.to_json)

    post_json(connection: "Pipelines", testCaseId: automated.id, ref: "main")

    expect(last_response).to have_http_status(201)
    run = TestManagement::TestRun.where(project_id: project.id).sole
    expect(json).to include("_type" => "TestManagementCiTrigger", "status" => "triggered", "runId" => run.id,
                            "iterationId" => run.current_iteration.id, "iterationNumber" => 1, "ref" => "main",
                            "grep" => "pays", "url" => "https://gitlab.example.com/p/77", "externalId" => "77")
    expect(json["_links"]["run"]["href"]).to eq(api_v3_paths.test_management_run(run.id))
    expect(last_response.body).not_to include("glptt-trigger-secret")

    get api_v3_paths.test_management_run(run.id)
    expect(json["ciTrigger"]).to include("status" => "triggered", "url" => "https://gitlab.example.com/p/77")
  end

  it "answers 502 with the error when the provider refuses" do
    stub_request(:post, pipeline_url).to_return(status: 400, body: { message: { base: ["Reference not found"] } }.to_json)

    post_json(connection: connection.id.to_s, suiteId: suite.id, ref: "nope")

    expect(last_response).to have_http_status(502)
    expect(json).to include("status" => "failed", "error" => "HTTP 400")
  end

  it "adds an iteration to an existing run" do
    stub_request(:post, pipeline_url).to_return(status: 201, body: "{}")
    run = create(:tm_test_run, project:)
    run.add_cases!([automated])

    post_json(connection: "Pipelines", mode: "new_iteration", runId: run.id)

    expect(last_response).to have_http_status(201)
    expect(json["runId"]).to eq(run.id)
  end

  it "validates the request" do
    post_json(connection: "unknown", suiteId: suite.id)
    expect(last_response).to have_http_status(422)

    post_json(connection: "Pipelines")
    expect(last_response).to have_http_status(422)
    expect(json["message"]).to include("Choose a run, a folder or a test case")

    post_json(connection: "Pipelines", suiteId: 0)
    expect(last_response).to have_http_status(404)
  end

  it "needs trigger_test_automation" do
    login_as(runner)
    post_json(connection: "Pipelines", suiteId: suite.id)
    expect(last_response).to have_http_status(403)
  end
end
