# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management automation results" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:uploader) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs upload_test_results] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:login_case) do
    create(:tm_test_case, project:, title: "Sign in",
                          automation_reference: "login.spec.ts#Login › signs in with valid credentials")
  end
  shared_let(:wrong_case) { create(:tm_test_case, project:, title: "Wrong password") }

  let(:current) { uploader }
  let(:results_path) { api_v3_paths.project_test_management_automation_results(project.id) }
  let(:report) do
    File.read(File.expand_path("../../../../fixtures/files/test_management/playwright-report.json", __dir__))
        .gsub("__CASE_ID__", wrong_case.id.to_s)
  end

  before { login_as(current) if current }

  # Not a memoized let: several examples make more than one request.
  def json = JSON.parse(last_response.body)

  def upload(metadata: {}, attachments: [], content: report, path: results_path)
    params = { file: mock_uploaded_file(name: "results.json", content_type: "application/json", content:) }
    params[:metadata] = metadata.to_json if metadata
    params[:attachments] = attachments if attachments.any?
    post path, params
  end

  def post_json(body, path: results_path)
    header "Content-Type", "application/json"
    post path, body.to_json
  end

  def expect_error(status, identifier)
    expect(last_response).to have_http_status(status)
    expect(json["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{identifier}")
  end

  describe "POST multipart" do
    it "creates a run (201) and reports the import" do
      upload(metadata: { externalRef: "github:shop:1:1", ci: { workflow: "e2e", runNumber: "7" } })

      expect(last_response).to have_http_status(201)
      expect(json).to include("_type" => "TestManagementIngestResult", "createdRun" => true, "replay" => false)
      expect(json["import"]).to include("parsedCount" => 5, "matchedCount" => 3, "unmatchedCount" => 2)
      expect(json["run"]).to include("externalRef" => "github:shop:1:1", "source" => "automation", "state" => "in_progress")
      expect(json["run"]["statusCounts"]).to include("passed" => 1, "failed" => 1)
    end

    it "answers 200 for a second shard and marks a repeated payload as replay" do
      upload(metadata: { externalRef: "ci:shards" })
      run_id = json["run"]["id"]

      upload(metadata: { externalRef: "ci:shards" })

      expect(last_response).to have_http_status(200)
      expect(json).to include("createdRun" => false, "replay" => true)
      expect(json["run"]["id"]).to eq(run_id)
    end

    it "stores attachments on the matching run case using attachmentPaths" do
      files = [mock_uploaded_file(name: "test-failed-1.png", content_type: "image/png", content: "png"),
               mock_uploaded_file(name: "playwright-report.zip", content_type: "application/zip", content: "zip")]

      upload(metadata: { attachmentPaths: %w[login-firefox/test-failed-1.png playwright-report.zip] }, attachments: files)

      expect(last_response).to have_http_status(201)
      run = TestManagement::TestRun.find(json["run"]["id"])
      expect(run.run_cases.find_by(test_case: login_case).attachments.map(&:filename)).to eq(["test-failed-1.png"])
      expect(run.attachments.map(&:filename)).to eq(["playwright-report.zip"])
      expect(json["import"]["attachmentsCount"]).to eq(2)
    end

    it "completes the run with closeRun" do
      upload(metadata: { closeRun: true })

      expect(json["run"]).to include("state" => "completed", "completionSource" => "automation")
    end

    it "answers 400 without a file part and for invalid metadata" do
      # Without a file Rack::Test would send a urlencoded form (Grape answers 415); force multipart.
      post results_path, { metadata: "{}" }, { "CONTENT_TYPE" => "multipart/form-data" }
      expect_error(400, "InvalidRequestBody")

      post results_path, { file: mock_uploaded_file(name: "r.json", content: report), metadata: "{nope" }
      expect_error(400, "InvalidRequestBody")
    end

    it "answers 413 for a report above the limit" do
      stub_const("TestManagement::Automation::IngestService::MAX_BYTES", 10)

      upload

      expect_error(413, "PayloadTooLarge")
    end

    it "answers 413 for a JSON body above the limit before parsing it" do
      stub_const("TestManagement::Automation::IngestService::MAX_BYTES", 10)
      allow(TestManagement::Automation::Parsers::Json).to receive(:load).and_call_original

      post_json({ tests: [{ caseId: wrong_case.id.to_s, status: "passed" }] })

      expect_error(413, "PayloadTooLarge")
      expect(TestManagement::Automation::Parsers::Json).not_to have_received(:load)
    end

    it "answers 422 for invalid options and a report without tests" do
      upload(metadata: { caseMatcher: "magic" })
      expect_error(422, "UnprocessableContent")

      upload(content: %({"suites":[]}))
      expect_error(422, "UnprocessableContent")
    end
  end

  describe "POST JSON" do
    it "accepts the native format with options at the top level" do
      post_json({ externalRef: "native:1", tests: [{ caseId: wrong_case.id, status: "failed", durationMs: 10 }] })

      expect(last_response).to have_http_status(201)
      expect(json["run"]["statusCounts"]).to include("failed" => 1)
    end

    it "accepts a Playwright report under 'report' and options under 'metadata'" do
      post_json({ report: JSON.parse(report), metadata: { runName: "Nightly" } })

      expect(last_response).to have_http_status(201)
      expect(json["run"]["name"]).to eq("Nightly")
    end

    it "answers 400 for a body without a report" do
      post_json({ externalRef: "x" })

      expect_error(400, "InvalidRequestBody")
    end
  end

  describe "POST …/runs/:run_id/results" do
    let(:run) { create(:tm_test_run, :automation, project:, state: "in_progress") }

    it "reports into the given run" do
      post_json({ tests: [{ caseId: wrong_case.id, status: "passed" }] },
                path: api_v3_paths.project_test_management_run_results(project.id, run.id))

      expect(last_response).to have_http_status(200)
      expect(json["run"]["id"]).to eq(run.id)
    end

    it "answers 409 for a completed or cancelled run" do
      %i[completed cancelled].each do |trait|
        finished = create(:tm_test_run, trait, project:)
        post_json({ tests: [{ caseId: wrong_case.id, status: "passed" }] },
                  path: api_v3_paths.project_test_management_run_results(project.id, finished.id))

        expect_error(409, "UpdateConflict")
      end
    end

    it "answers 404 for a run of another project" do
      other = create(:tm_test_run)
      post_json({ tests: [{ caseId: wrong_case.id, status: "passed" }] },
                path: api_v3_paths.project_test_management_run_results(project.id, other.id))

      expect_error(404, "NotFound")
    end
  end

  describe "permissions" do
    context "without the upload permission" do
      let(:current) { viewer }

      it "answers 403" do
        upload

        expect_error(403, "MissingPermission")
      end
    end

    context "for a project the user cannot see" do
      let(:results_path) { api_v3_paths.project_test_management_automation_results(create(:project).id) }

      it "answers 404" do
        upload

        expect_error(404, "NotFound")
      end
    end
  end

  describe "Bearer API token", with_settings: { api_tokens_enabled: true } do
    let(:token) { create(:api_token, user: uploader) }
    let(:current) { nil }

    it "authenticates CI uploads" do
      header "Authorization", "Bearer #{token.plain_value}"
      upload(metadata: { externalRef: "token:1" })

      expect(last_response).to have_http_status(201)
      expect(TestManagement::TestRun.find(json["run"]["id"]).author).to eq(uploader)
    end
  end

  describe "GET …/runs" do
    let!(:ci_run) { create(:tm_test_run, :automation, project:, external_ref: "github:shop:9:1") }
    let!(:manual_run) { create(:tm_test_run, project:) }

    it "filters by externalRef" do
      get "#{api_v3_paths.project_test_management_runs(project.id)}?externalRef=github:shop:9:1"

      expect(last_response).to have_http_status(200)
      expect(json["_type"]).to eq("Collection")
      expect(json["_embedded"]["elements"].pluck("id")).to eq([ci_run.id])
    end

    it "filters by source" do
      get "#{api_v3_paths.project_test_management_runs(project.id)}?source=manual"

      expect(json["_embedded"]["elements"].pluck("id")).to eq([manual_run.id])
    end
  end
end
