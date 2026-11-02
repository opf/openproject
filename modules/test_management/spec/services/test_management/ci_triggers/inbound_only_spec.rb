# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_certificates"

# Inbound-only connections (0015): "Run in CI" prepares the run and iteration but never calls the
# server; ManualStart renders the CI variables and a command to start the pipeline by hand.
RSpec.describe TestManagement::CiTriggers::TriggerService, "inbound only", :webmock do
  shared_let(:project) { create(:project, identifier: "shop-web", enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:case_a) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }

  let(:connection) do
    create(:tm_ci_connection, :self_hosted_gitlab, :inbound_only, project:, name: "Internal GitLab",
                                                                  trigger_token: nil, token: nil)
  end

  # Explicit class: inside `describe ManualStart` below, described_class is ManualStart.
  def trigger = TestManagement::CiTriggers::TriggerService.new(user:).call({ project:, connection:, suite: })

  it "prepares run and iteration with status manual and sends nothing" do
    call = trigger

    expect(call).to be_success
    outcome = call.result
    expect(outcome).to be_manual
    expect(WebMock).not_to have_requested(:any, //)
    expect(outcome.run.reload).to have_attributes(ci_trigger_status: "manual", ci_trigger_url: nil, connection_id: connection.id)
    expect(outcome.iteration.reload.ci_metadata["trigger"]).to include("status" => "manual", "ref" => "main",
                                                                       "grep" => "adds\\ item")
  end

  describe TestManagement::CiTriggers::ManualStart do
    let(:outcome) { trigger.result }
    let(:start) do
      described_class.new(connection:, run: outcome.run, iteration: outcome.iteration, op_url: "https://openproject.example.com/")
    end

    it "lists the CI variables" do
      expect(start.variables).to eq(
        "OP_URL" => "https://openproject.example.com", "OP_PROJECT" => "shop-web", "OP_CONNECTION" => "Internal GitLab",
        "OP_RUN_ID" => outcome.run.id.to_s, "OP_ITERATION_ID" => outcome.iteration.id.to_s, "OP_GREP" => "adds\\ item"
      )
      expect(start.variables_text).to include("OP_CONNECTION='Internal GitLab'", "OP_GREP='adds\\ item'")
    end

    it "builds a GitLab trigger command below the sub-path with a placeholder token" do
      command = start.command

      expect(command).to include("https://git.example.com/gitlab/api/v4/projects/qa%2Fweb%2Fshop/trigger/pipeline",
                                 "$GITLAB_TRIGGER_TOKEN", "'variables[OP_RUN_ID]=#{outcome.run.id}'")
      expect(command).not_to include("glptt", "glpat", "--cacert", "--insecure", " -k ")
    end

    it "references the connection's CA and escapes values" do
      connection.update_columns(ca_certificate: TestManagementCertificates.ca.to_pem)
      expect(start.command).to include("--cacert ./ca.pem")

      jenkins = create(:tm_ci_connection, :jenkins, :inbound_only, project:, base_url: "https://example.com/jenkins",
                                                                   ci_username: "qa bot;rm")
      jenkins_start = described_class.new(connection: jenkins, run: outcome.run, iteration: outcome.iteration, op_url: "https://op")
      expect(jenkins_start.command).to include("--user 'qa bot;rm':\"$JENKINS_API_TOKEN\"", "https://example.com/jenkins/job/qa/job/e2e/buildWithParameters")
      expect(jenkins_start.command).not_to include("jenkins-api-secret")
    end
  end
end
