# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management results and step results" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:tester) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs upload_test_results] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { tester }
  let(:run) { create(:tm_test_run, project:, state: "in_progress") }
  let(:test_case) { create(:tm_test_case, project:, title: "Pay by card") }
  let!(:steps) do
    ["Open the cart", "Enter the card number", "Confirm the payment"].each_with_index.map do |action, index|
      create(:tm_test_step, test_case:, position: index, action:)
    end
  end
  let(:run_case) { create(:tm_test_run_case, test_run: run, test_case:) }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def post_json(path, body)
    header "Content-Type", "application/json"
    post path, body.to_json
  end

  describe "POST run_cases/:id/results" do
    let(:path) { api_v3_paths.test_management_run_case_results(run_case.id) }

    it "records a manual result with step results" do
      post_json(path, { comment: "manual", errorMessage: "No receipt",
                        stepResults: [{ testStepId: steps[0].id, status: "passed" },
                                      { testStepId: steps[1].id, status: "failed", actualResult: "Card rejected" }] })

      expect(last_response).to have_http_status(:created)
      expect(json["_type"]).to eq("TestManagementResult")
      expect(json).to include("status" => "failed", "errorMessage" => "No receipt", "failedStep" => 2)
      expect(json["stepResults"].pluck("status")).to eq(%w[passed failed untested])
      expect(json["stepResults"].second).to include("actualResult" => "Card rejected", "testStepId" => steps[1].id,
                                                    "_type" => "TestManagementStepResult")
      expect(run_case.reload.status).to eq("failed")
    end

    it "rejects unknown steps and empty requests" do
      post_json(path, { stepResults: [{ testStepId: 0, status: "passed" }] })
      expect(last_response).to have_http_status(:unprocessable_entity)

      post_json(path, {})
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "answers 409 for a finished run" do
      run.update!(state: "completed")
      post_json(path, { status: "passed" })
      expect(last_response).to have_http_status(:conflict)
    end

    context "as viewer" do
      let(:current) { viewer }

      it "is forbidden" do
        post_json(path, { status: "passed" })
        expect(last_response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET results/:id and run case results" do
    let!(:result) do
      create(:tm_test_result, run_case:, status: "failed", error_message: "boom", error_trace: "Error: boom\n at x").tap do |r|
        create(:tm_test_step_result, result: r, test_step: steps[0], position: 0, status: "failed", error_message: "boom")
      end
    end

    it "returns the error and the step results" do
      get api_v3_paths.test_management_result(result.id)

      expect(last_response).to have_http_status(:ok)
      expect(json).to include("errorMessage" => "boom", "errorTrace" => "Error: boom\n at x", "failedStep" => 1)
      expect(json["stepResults"].first).to include("position" => 1, "status" => "failed", "errorMessage" => "boom")
      expect(json.dig("_links", "runCase", "href")).to eq(api_v3_paths.test_management_run_case(run_case.id))
    end

    it "embeds errors and step results in the run case" do
      get api_v3_paths.test_management_run_case(run_case.id)

      entry = json["results"].last
      expect(entry).to include("errorMessage" => "boom", "failedStep" => 1)
      expect(entry["stepResults"].first["status"]).to eq("failed")
      expect(json.dig("_links", "addResult", "href")).to eq(api_v3_paths.test_management_run_case_results(run_case.id))
    end

    context "without access" do
      let(:current) { outsider }

      it "is not found" do
        get api_v3_paths.test_management_result(result.id)
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "uploads with steps" do
    let(:path) { api_v3_paths.project_test_management_automation_results(project.id) }
    let(:report) do
      File.read(File.expand_path("../../../../fixtures/files/test_management/steps/cucumber.json", __dir__))
          .gsub("__CASE_ID__", test_case.id.to_s)
    end

    it "accepts a Cucumber JSON array as report and stores step results" do
      post_json(path, { report: JSON.parse(report), stepsAfterFailure: "blocked" })

      expect(last_response).to have_http_status(:created)
      result = TestManagement::TestRunCase.find_by(test_case_id: test_case.id).results.last
      expect(result.error_message).to start_with("expected 14 but got 7")
      expect(result.step_results.count(&:reported?)).to be >= 1
    end

    it "rejects an unknown stepsAfterFailure value" do
      post_json(path, { report: JSON.parse(report), stepsAfterFailure: "maybe" })
      expect(last_response).to have_http_status(:unprocessable_entity)
    end
  end
end
