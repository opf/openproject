# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management milestones", :disable_ssrf_filter, :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs manage_test_milestones view_work_packages
                           trigger_test_automation]
           })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:cases_only) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let(:current_user) { manager }
  let(:list_path) { api_v3_paths.project_test_management_milestones(project.id) }

  before { login_as(current_user) }

  def json = JSON.parse(last_response.body)

  def send_json(method, path, body)
    public_send(method, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  describe "GET list" do
    let!(:release) { create(:tm_milestone, project:, name: "Release 2.0") }
    let!(:sprint) { create(:tm_milestone, project:, parent: release, name: "Sprint 14") }
    let!(:done) { create(:tm_milestone, :completed, project:, name: "Release 1.9") }

    before do
      run = create(:tm_test_run, project:, milestone: sprint)
      create(:tm_test_run_case, test_run: run, status: "passed")
      create(:tm_test_run_case, test_run: run, status: "skipped")
    end

    it "lists milestones with progress" do
      get list_path

      expect(last_response).to have_http_status(200)
      elements = json["_embedded"]["elements"]
      expect(elements.pluck("name")).to contain_exactly("Release 2.0", "Sprint 14", "Release 1.9")
      parent = elements.find { it["id"] == release.id }
      expect(parent).to include("_type" => "TestManagementMilestone", "status" => "open", "totalCases" => 2,
                                "passRate" => 100, "runsCount" => 1)
      expect(parent["_links"]["children"].pluck("title")).to eq(["Sprint 14"])
      expect(parent["_links"]).to include("start", "complete", "update", "delete")
    end

    it "filters by status and parentId" do
      get "#{list_path}?status=completed"
      expect(json["_embedded"]["elements"].pluck("name")).to eq(["Release 1.9"])

      get "#{list_path}?parentId=#{release.id}"
      expect(json["_embedded"]["elements"].pluck("name")).to eq(["Sprint 14"])
    end

    context "as a viewer" do
      let(:current_user) { viewer }

      it "lists without action links" do
        get list_path
        expect(last_response).to have_http_status(200)
        expect(json["_embedded"]["elements"].first["_links"]).not_to include("start", "update", "delete")
      end
    end

    context "without view_test_runs" do
      let(:current_user) { cases_only }

      it "is forbidden" do
        get list_path
        expect(last_response).to have_http_status(403)
      end
    end

    it "is not found when milestones are disabled" do
      create(:tm_project_setting, project:).update!(enable_milestones: false)
      get list_path
      expect(last_response).to have_http_status(404)
      get api_v3_paths.test_management_milestone(release.id)
      expect(last_response).to have_http_status(404)
    end
  end

  describe "POST create" do
    it "creates a milestone (201)" do
      work_package = create(:work_package, project:)
      send_json(:post, list_path, name: "Release 2.0", description: { raw: "GA" }, dueDate: "2026-12-01",
                                  workPackageIds: [work_package.id])

      expect(last_response).to have_http_status(201)
      expect(json).to include("name" => "Release 2.0", "dueDate" => "2026-12-01", "status" => "open")
      expect(json["description"]["raw"]).to eq("GA")
      expect(json["_links"]["workPackages"].pluck("href")).to eq([api_v3_paths.work_package(work_package.id)])
    end

    it "answers 422 for invalid input" do
      send_json(:post, list_path, name: "", startDate: "2026-12-10", dueDate: "2026-12-01")
      expect(last_response).to have_http_status(422)
    end

    context "as a viewer" do
      let(:current_user) { viewer }

      it "is forbidden" do
        send_json(:post, list_path, name: "Release 2.0")
        expect(last_response).to have_http_status(403)
      end
    end
  end

  describe "single milestone" do
    let!(:milestone) { create(:tm_milestone, project:, name: "Release 2.0") }
    let(:path) { api_v3_paths.test_management_milestone(milestone.id) }

    it "reads, updates and deletes" do
      get path
      expect(json).to include("id" => milestone.id, "overdue" => false)
      expect(json["_links"]["runs"]["href"]).to end_with("milestoneId=#{milestone.id}")

      send_json(:patch, path, name: "Release 2.1")
      expect(last_response).to have_http_status(200)
      expect(milestone.reload.name).to eq("Release 2.1")

      delete path
      expect(last_response).to have_http_status(204)
      expect(TestManagement::Milestone.exists?(milestone.id)).to be(false)
    end

    # Every APIv3 POST needs a JSON Content-Type (core enforce_content_type). A bare Rack::Test
    # `post` sends application/x-www-form-urlencoded and gets 415, so send an empty JSON object.
    def transition(action)
      send_json(:post, api_v3_paths.public_send(:"test_management_milestone_#{action}", milestone.id), {})
    end

    it "starts, completes and reopens; 409 for an impossible transition" do
      transition(:start)
      expect(last_response).to have_http_status(200)
      expect(json["status"]).to eq("started")
      transition(:start)
      expect(last_response).to have_http_status(409)
      transition(:complete)
      expect(last_response).to have_http_status(200)
      expect(json).to include("status" => "completed")
      expect(json["_links"]).to include("reopen")
      transition(:reopen)
      expect(last_response).to have_http_status(200)
      expect(json["status"]).to eq("started")
    end

    it "rejects a transition without a JSON Content-Type (415), like every APIv3 POST" do
      post api_v3_paths.test_management_milestone_start(milestone.id)
      expect(last_response).to have_http_status(415)
      expect(milestone.reload.status).to eq("open")
    end

    it "is 404 for users who cannot view runs" do
      login_as(cases_only)
      get path
      expect(last_response).to have_http_status(404)
    end
  end

  describe "runs" do
    it "links the milestone and filters by milestoneId" do
      milestone = create(:tm_milestone, project:)
      assigned = create(:tm_test_run, project:, milestone:)
      create(:tm_test_run, project:)

      get "#{api_v3_paths.project_test_management_runs(project.id)}?milestoneId=#{milestone.id}"
      elements = json["_embedded"]["elements"]
      expect(elements.pluck("id")).to eq([assigned.id])
      expect(elements.first["_links"]["milestone"]["href"]).to eq(api_v3_paths.test_management_milestone(milestone.id))
    end
  end

  describe "Run in CI" do
    shared_let(:suite) { create(:tm_suite, project:) }
    shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/a.spec.ts#pays") }
    shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:, name: "E2E") }

    before do
      stub_request(:post, "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches").to_return(status: 204)
    end

    it "assigns the new run to the milestone given by M-id or name; unknown is 422" do
      milestone = create(:tm_milestone, project:, name: "Release 2.0")
      path = api_v3_paths.project_test_management_ci_triggers(project.id)

      send_json(:post, path, connection: "E2E", suiteId: suite.id, milestone: "M#{milestone.id}")
      expect(last_response).to have_http_status(201)
      expect(TestManagement::TestRun.find(json["runId"]).milestone).to eq(milestone)

      send_json(:post, path, connection: "E2E", suiteId: suite.id, milestone: "release 2.0")
      expect(TestManagement::TestRun.find(json["runId"]).milestone).to eq(milestone)

      send_json(:post, path, connection: "E2E", suiteId: suite.id, milestone: "Nope")
      expect(last_response).to have_http_status(422)
      expect(json["message"]).to include("Unknown milestone")
    end
  end
end
