# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../support/test_management_certificates"
require "rack/test"

# Self-hosted servers (0015) in APIv3: connection fields and "Run in CI" on inbound-only connections.
RSpec.describe "APIv3 test management self-hosted CI", :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, identifier: "shop-sh", enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation
                                                    manage_test_ci] })
  end
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/a.spec.ts#pays") }
  shared_let(:connection) do
    create(:tm_ci_connection, :self_hosted_gitlab, :inbound_only, project:, name: "Internal",
                                                                  ca_certificate: TestManagementCertificates.ca.to_pem)
  end

  before { login_as(user) }

  def json = JSON.parse(last_response.body)

  it "renders inboundOnly, serverVersion and a CA summary, never the PEM or tokens" do
    connection.update_columns(server_version: "17.5.1")

    get api_v3_paths.test_management_ci_connection(connection.id)

    expect(last_response).to have_http_status(200)
    expect(json).to include("inboundOnly" => true, "serverVersion" => "17.5.1", "baseUrl" => "https://git.example.com/gitlab")
    expect(json["caCertificates"]).to contain_exactly(hash_including("subject" => "Example Internal Root CA", "expired" => false))
    expect(last_response.body).not_to include("BEGIN CERTIFICATE", "glptt-selfhosted-secret", "glpat-selfhosted-secret")
  end

  it "prepares the run for an inbound-only connection and returns manualStart (201, nothing sent)" do
    post api_v3_paths.project_test_management_ci_triggers(project.id),
         { connection: "Internal", testCaseId: automated.id }.to_json, { "CONTENT_TYPE" => "application/json" }

    expect(last_response).to have_http_status(201)
    expect(WebMock).not_to have_requested(:any, //)
    run = TestManagement::TestRun.where(project_id: project.id).sole
    expect(json).to include("status" => "manual", "runId" => run.id)
    expect(json["manualStart"]["variables"]).to include("OP_RUN_ID" => run.id.to_s, "OP_PROJECT" => "shop-sh",
                                                        "OP_GREP" => "pays")
    expect(json["manualStart"]["command"]).to include("https://git.example.com/gitlab/api/v4/projects/qa%2Fweb%2Fshop/trigger/pipeline",
                                                      "$GITLAB_TRIGGER_TOKEN", "--cacert ./ca.pem")

    get api_v3_paths.test_management_run(run.id)
    expect(json["ciTrigger"]).to include("status" => "manual")
  end
end
