# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require_relative "../../../../support/test_management_assistant"

RSpec.describe "APIv3 test management assistant generations" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  include_context "with test assistant provider"

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases add_test_cases use_test_assistant view_work_packages]
           })
  end
  shared_let(:no_assistant) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let(:current_user) { user }
  let(:create_path) { api_v3_paths.project_test_management_assistant_generations(project.id) }

  before do
    allow(TestManagement::Assistant::GenerateJob).to receive(:perform_later)
    login_as(current_user)
  end

  def json = JSON.parse(last_response.body)

  def send_json(method, path, body)
    public_send(method, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  describe "POST generations" do
    it "accepts the request (202) and returns the queued generation" do
      send_json(:post, create_path, { sourceType: "text", source: { text: "Users can log in." }, count: 3,
                                      types: %w[positive], labels: %w[ai] })

      expect(last_response).to have_http_status(202)
      expect(json).to include("_type" => "TestManagementAssistantGeneration", "status" => "queued",
                              "sourceType" => "text", "count" => 3, "labels" => ["ai"])
      generation = TestManagement::AssistantGeneration.find(json["id"])
      expect(TestManagement::Assistant::GenerateJob).to have_received(:perform_later).with(generation.id)
    end

    it "validates (422), needs JSON (415) and the permission (403)" do
      send_json(:post, create_path, { sourceType: "text", source: { text: "" } })
      expect(last_response).to have_http_status(422)

      post create_path, "sourceType=text", { "CONTENT_TYPE" => "text/plain" }
      expect(last_response).to have_http_status(415)

      login_as(no_assistant)
      send_json(:post, create_path, { sourceType: "text", source: { text: "x" } })
      expect(last_response).to have_http_status(403)
    end
  end

  describe "GET and save" do
    let(:generation) { create(:tm_assistant_generation, :done, project:, user:) }
    let(:show_path) { api_v3_paths.test_management_assistant_generation(generation.id) }
    let(:save_path) { api_v3_paths.test_management_assistant_generation_save(generation.id) }

    it "returns the own generation with its drafts and save link" do
      get show_path

      expect(last_response).to have_http_status(200)
      expect(json["drafts"].first["steps"].first).to include("expectedResult" => "An email is sent")
      expect(json["usage"]).to eq("promptTokens" => 120, "completionTokens" => 80, "totalTokens" => 200)
      expect(json.dig("_links", "save", "href")).to eq(save_path)
    end

    it "404s for another user's generation" do
      foreign = create(:tm_assistant_generation, :done, project:, user: no_assistant)

      get api_v3_paths.test_management_assistant_generation(foreign.id)
      expect(last_response).to have_http_status(404)
    end

    it "saves the drafts (201), optionally edited" do
      send_json(:post, save_path, { drafts: [{ title: "Edited via API", priority: "low",
                                               steps: [{ action: "a", expectedResult: "b" }] }] })

      expect(last_response).to have_http_status(201)
      expect(json["_type"]).to eq("TestManagementAssistantSaveResult")
      expect(json["testCases"].pluck("title")).to eq(["Edited via API"])
      expect(TestManagement::TestCase.find(json["savedCaseIds"].first).status).to eq("draft")
    end

    it "409s while the generation is not done" do
      generation.update!(status: "running")
      send_json(:post, save_path, {})

      expect(last_response).to have_http_status(409)
    end
  end
end
