# frozen_string_literal: true

require "spec_helper"

# WebMock only for examples tagged :webmock; :disable_ssrf_filter lets OpenProject.httpx reach
# the stubbed hosts.
RSpec.describe TestManagement::CiTriggers::TriggerService, :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, identifier: "shop-web", enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:case_a) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:case_b) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#removes item") }
  shared_let(:manual) { create(:tm_test_case, project:, suite:) }

  let(:grep) { "adds\\ item|removes\\ item" }

  def trigger(connection, **params)
    described_class.new(user:).call({ project:, connection:, suite: }.merge(params))
  end

  def inputs_for(outcome)
    { "op_run_id" => outcome.run.id.to_s, "op_iteration_id" => outcome.iteration.id.to_s,
      "op_project" => "shop-web", "op_grep" => grep }
  end

  describe "new_run" do
    let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

    it "pre-creates a run with all cases of the folder and iteration 1, then dispatches the GitHub workflow" do
      stub = stub_request(:post, "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches")
               .with(headers: { "Authorization" => "Bearer ghp_trigger_secret" })
               .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                          body: { workflow_run_id: 9876, html_url: "https://github.com/my-org/shop/actions/runs/9876" }.to_json)

      call = trigger(connection)
      expect(call).to be_success
      outcome = call.result
      expect(outcome).to be_triggered
      expect(outcome).to have_attributes(url: "https://github.com/my-org/shop/actions/runs/9876", external_id: "9876",
                                         ref: "main", grep:)

      run = outcome.run.reload
      expect(run).to have_attributes(source: "automation", state: "new", connection_id: connection.id,
                                     ci_trigger_status: "triggered",
                                     ci_trigger_url: "https://github.com/my-org/shop/actions/runs/9876")
      expect(run.name).to include("Checkout", connection.name)
      expect(run.run_cases.pluck(:test_case_id)).to contain_exactly(case_a.id, case_b.id, manual.id)
      expect(outcome.iteration.reload).to have_attributes(number: 1, source: "automation", connection_id: connection.id)
      expect(outcome.iteration.ci_metadata["trigger"]).to include("status" => "triggered", "externalId" => "9876")

      expect(stub.with(body: { "ref" => "main", "inputs" => inputs_for(outcome), "return_run_details" => true }))
        .to have_been_requested
    end

    it "keeps the run and records the provider error when the dispatch fails" do
      stub_request(:post, %r{api\.github\.com/repos/my-org/shop/actions/workflows/e2e\.yml/dispatches})
        .to_return(status: 422, headers: { "Content-Type" => "application/json" },
                   body: { message: "Unexpected inputs provided: [\"op_grep\"]" }.to_json)

      outcome = trigger(connection).result
      expect(outcome).not_to be_triggered
      expect(outcome.error).to eq("HTTP 422: Unexpected inputs provided: [\"op_grep\"]")
      expect(outcome.run.reload).to have_attributes(ci_trigger_status: "failed", ci_trigger_error: outcome.error)
      expect(outcome.iteration.reload.ci_metadata.dig("trigger", "status")).to eq("failed")
    end

    it "never leaks the token into the recorded error" do
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_return(status: 401,
                                                                     body: { message: "bad ghp_trigger_secret" }.to_json)
      outcome = trigger(connection).result
      expect(outcome.error).to eq("HTTP 401: bad [FILTERED]")
      expect(outcome.run.reload.ci_trigger_error).not_to include("ghp_trigger_secret")
    end

    it "reports network errors without raising" do
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_timeout
      outcome = trigger(connection).result
      expect(outcome.status).to eq("failed")
      expect(outcome.error).to be_present
    end

    it "does nothing when the contract fails" do
      call = described_class.new(user: create(:user)).call(project:, connection:, suite:)
      expect(call).to be_failure
      expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
      expect(a_request(:post, %r{\Ahttps?://api\.github\.com(?:/|\z)})).not_to have_been_made
    end
  end

  describe "new_iteration" do
    let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }
    let!(:run) { create(:tm_test_run, project:, name: "Regression") }

    before do
      create(:tm_test_run_case, test_run: run, test_case: case_a)
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_return(status: 204)
    end

    it "starts the next iteration of the run and adds missing cases of the scope" do
      first = trigger(connection, mode: "new_iteration", run:, suite: nil).result
      expect(first.iteration.number).to eq(1)
      expect(first.grep).to eq("adds\\ item")
      expect(first.url).to eq("https://github.com/my-org/shop/actions/workflows/e2e.yml")

      second = trigger(connection, mode: "new_iteration", run:, test_case: case_b, suite: nil).result
      expect(second.run).to eq(run)
      expect(second.iteration.number).to eq(2)
      expect(run.reload.current_iteration).to eq(second.iteration)
      expect(run.run_cases.pluck(:test_case_id)).to contain_exactly(case_a.id, case_b.id)
    end
  end

  describe "providers" do
    it "GitLab: trigger token, ref and OP_* variables" do
      connection = create(:tm_ci_connection, :gitlab_trigger, project:, base_url: "https://gitlab.example.com")
      stub = stub_request(:post, "https://gitlab.example.com/api/v4/projects/group%2Fsub%2Fapp/trigger/pipeline")
               .to_return(status: 201, body: { id: 555,
                                               web_url: "https://gitlab.example.com/group/sub/app/-/pipelines/555" }.to_json)

      outcome = trigger(connection, ref: "release/2.4").result
      expect(outcome).to have_attributes(status: "triggered", external_id: "555",
                                         url: "https://gitlab.example.com/group/sub/app/-/pipelines/555")
      expect(stub.with(body: hash_including("token" => "glptt-trigger-secret", "ref" => "release/2.4",
                                            "variables" => { "OP_RUN_ID" => outcome.run.id.to_s,
                                                             "OP_ITERATION_ID" => outcome.iteration.id.to_s,
                                                             "OP_PROJECT" => "shop-web", "OP_GREP" => grep })))
        .to have_been_requested
    end

    it "Jenkins: Basic auth, parameters, build token and the queue item" do
      connection = create(:tm_ci_connection, :jenkins, project:, trigger_token: "build-tok")
      stub = stub_request(:post, "https://jenkins.example.com/job/qa/job/e2e/buildWithParameters")
               .with(basic_auth: %w[op-bot jenkins-api-secret])
               .to_return(status: 201, headers: { "Location" => "https://jenkins.example.com/queue/item/77/" })

      outcome = trigger(connection).result
      expect(outcome).to have_attributes(status: "triggered", url: "https://jenkins.example.com/job/qa/job/e2e",
                                         external_id: "https://jenkins.example.com/queue/item/77/")
      expect(stub.with(body: hash_including("OP_RUN_ID" => outcome.run.id.to_s, "OP_GREP" => grep,
                                            "OP_PROJECT" => "shop-web", "OP_REF" => "main", "token" => "build-tok")))
        .to have_been_requested
    end

    it "Jenkins: fetches a crumb and retries once on 403" do
      connection = create(:tm_ci_connection, :jenkins, project:)
      stub_request(:post, "https://jenkins.example.com/job/qa/job/e2e/buildWithParameters")
        .to_return({ status: 403 }, { status: 201 })
      crumb = stub_request(:get, "https://jenkins.example.com/crumbIssuer/api/json")
                .to_return(status: 200, headers: { "Set-Cookie" => "JSESSIONID.abc=xyz; Path=/" },
                           body: { crumbRequestField: "Jenkins-Crumb", crumb: "c0ffee" }.to_json)

      expect(trigger(connection).result).to be_triggered
      expect(crumb).to have_been_requested
      expect(a_request(:post, "https://jenkins.example.com/job/qa/job/e2e/buildWithParameters")
               .with(headers: { "Jenkins-Crumb" => "c0ffee", "Cookie" => "JSESSIONID.abc=xyz" })).to have_been_made
    end

    it "Gitea: token header, refs/heads ref, return_run_details" do
      connection = create(:tm_ci_connection, :gitea, project:)
      stub = stub_request(:post, "https://gitea.example.com/api/v1/repos/my-org/shop/actions/workflows/op-tests.yml/dispatches")
               .with(query: { return_run_details: "true" }, headers: { "Authorization" => "token gitea-secret" })
               .to_return(status: 200, body: { workflow_run_id: 31,
                                               html_url: "https://gitea.example.com/my-org/shop/actions/runs/12" }.to_json)

      outcome = trigger(connection).result
      expect(outcome).to have_attributes(status: "triggered", external_id: "31",
                                         url: "https://gitea.example.com/my-org/shop/actions/runs/12")
      expect(stub.with(body: hash_including("ref" => "refs/heads/main"))).to have_been_requested
    end

    it "Gitea before 1.26: 204 links the workflow" do
      connection = create(:tm_ci_connection, :gitea, project:)
      stub_request(:post, %r{\Ahttps://gitea\.example\.com(?:/.*)?\z}).to_return(status: 204)
      expect(trigger(connection).result.url).to eq("https://gitea.example.com/my-org/shop/actions?workflow=op-tests.yml")
    end

    it "Forgejo: return_run_info in the body, 201 with the run number" do
      connection = create(:tm_ci_connection, :forgejo, project:)
      stub = stub_request(:post, "https://forgejo.example.com/api/v1/repos/my-org/shop/actions/workflows/op-tests.yml/dispatches")
               .with(headers: { "Authorization" => "token forgejo-secret" })
               .to_return(status: 201, body: { id: 88, run_number: 7, jobs: [] }.to_json)

      outcome = trigger(connection).result
      expect(outcome).to have_attributes(status: "triggered", external_id: "88",
                                         url: "https://forgejo.example.com/my-org/shop/actions/runs/7")
      expect(stub.with(body: hash_including("return_run_info" => true, "ref" => "refs/heads/main"))).to have_been_requested
    end

    it "Codeberg: Forgejo API on codeberg.org" do
      connection = create(:tm_ci_connection, :codeberg, project:)
      stub = stub_request(:post, "https://codeberg.org/api/v1/repos/my-org/shop/actions/workflows/op-tests.yml/dispatches")
               .with(headers: { "Authorization" => "token codeberg-secret" }).to_return(status: 204)

      expect(trigger(connection).result).to be_triggered
      expect(stub).to have_been_requested
    end

    it "Woodpecker: manual pipeline with variables" do
      connection = create(:tm_ci_connection, :woodpecker, project:)
      stub = stub_request(:post, "https://ci.example.com/api/repos/42/pipelines")
               .with(headers: { "Authorization" => "Bearer woodpecker-secret" })
               .to_return(status: 200, body: { id: 900, number: 15 }.to_json)

      outcome = trigger(connection, ref: "develop").result
      expect(outcome).to have_attributes(status: "triggered", external_id: "15",
                                         url: "https://ci.example.com/repos/42/pipeline/15")
      expect(stub.with(body: hash_including("branch" => "develop",
                                            "variables" => hash_including("OP_ITERATION_ID" => outcome.iteration.id.to_s))))
        .to have_been_requested
    end
  end
end
