# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management runs, run cases and imports" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs execute_test_runs] })
  end
  shared_let(:uploader) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs upload_test_results] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  let(:run) { create(:tm_test_run, :automation, :in_progress, project:) }
  let!(:run_case) { create(:tm_test_run_case, test_run: run, status: "failed") }
  let!(:skipped_case) { create(:tm_test_run_case, test_run: run, status: "skipped") }
  let!(:passed_case) { create(:tm_test_run_case, test_run: run, status: "passed") }
  let(:current) { manager }

  before { login_as(current) }

  # Not a memoized let: several examples make more than one request.
  def json = JSON.parse(last_response.body)

  # The API only accepts JSON (or multipart) bodies; a bare POST from Rack::Test is a urlencoded
  # form and is rejected with 415.
  def post_json(path, body = {})
    post path, body.to_json, { "CONTENT_TYPE" => "application/json" }
  end

  def expect_error(status, identifier)
    expect(last_response).to have_http_status(status)
    expect(json["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{identifier}")
  end

  def upload_attachment(path, name: "screenshot.png")
    post path, { metadata: { fileName: name }.to_json, file: mock_uploaded_file(name:, content_type: "image/png") }
  end

  describe "GET /api/v3/test_management/runs/:id" do
    it "renders the run with counts, pass rate without skipped cases and its run cases" do
      get api_v3_paths.test_management_run(run.id)

      expect(last_response).to have_http_status(200)
      expect(json).to include("_type" => "TestManagementRun", "id" => run.id, "source" => "automation",
                              "externalRef" => run.external_ref, "totalCases" => 3, "passRate" => 50)
      expect(json["statusCounts"]).to include("failed" => 1, "skipped" => 1, "passed" => 1)
      expect(json["runCases"].pluck("id")).to contain_exactly(run_case.id, skipped_case.id, passed_case.id)
      expect(json["_links"]).to include("complete", "cancel", "imports", "attachments")
    end

    it "answers 404 for a run in a project the user cannot see" do
      get api_v3_paths.test_management_run(create(:tm_test_run).id)

      expect_error(404, "NotFound")
    end
  end

  describe "POST …/complete and …/cancel" do
    it "completes an active run as automation by default" do
      post_json api_v3_paths.test_management_run_complete(run.id)

      expect(last_response).to have_http_status(200)
      expect(json).to include("state" => "completed", "completionSource" => "automation")
      expect(json["_links"]).not_to include("complete")
    end

    it "lets an uploader complete the run it reported into" do
      login_as(uploader)
      post_json api_v3_paths.test_management_run_complete(run.id)

      expect(last_response).to have_http_status(200)
    end

    it "answers 409 for a completed or cancelled run" do
      %i[completed cancelled].each do |trait|
        finished = create(:tm_test_run, trait, project:)

        post_json api_v3_paths.test_management_run_complete(finished.id)
        expect_error(409, "UpdateConflict")

        post_json api_v3_paths.test_management_run_cancel(finished.id)
        expect_error(409, "UpdateConflict")
      end
    end

    context "as a viewer" do
      let(:current) { viewer }

      it "answers 403" do
        post_json api_v3_paths.test_management_run_cancel(run.id)

        expect_error(403, "MissingPermission")
        expect(run.reload.state).to eq("in_progress")
      end
    end
  end

  describe "imports" do
    let!(:import) { create(:tm_automation_import, test_run: run, user: uploader, matched_count: 2) }

    it "lists the imports of a run" do
      get api_v3_paths.test_management_run_imports(run.id)

      expect(last_response).to have_http_status(200)
      expect(json["_embedded"]["elements"].pluck("id")).to eq([import.id])
    end

    it "renders one import" do
      get api_v3_paths.test_management_import(import.id)

      expect(json).to include("_type" => "TestManagementAutomationImport", "matchedCount" => 2, "format" => "playwright_json")
    end

    it "answers 404 for an import of an invisible project" do
      get api_v3_paths.test_management_import(create(:tm_automation_import).id)

      expect_error(404, "NotFound")
    end
  end

  describe "run cases" do
    it "renders a run case with its results" do
      create(:tm_test_result, run_case:, status: "failed", source: "automation", duration_ms: 1200)

      get api_v3_paths.test_management_run_case(run_case.id)

      expect(last_response).to have_http_status(200)
      expect(json).to include("_type" => "TestManagementRunCase", "status" => "failed", "testCaseId" => run_case.test_case_id)
      expect(json["results"].first).to include("status" => "failed", "source" => "automation", "durationMs" => 1200)
      expect(json["_links"]).to include("addAttachment")
    end

    it "answers 404 for a run case of an invisible project" do
      get api_v3_paths.test_management_run_case(create(:tm_test_run_case).id)

      expect_error(404, "NotFound")
    end
  end

  describe "attachments" do
    it "uploads and lists run case attachments" do
      upload_attachment(api_v3_paths.test_management_run_case_attachments(run_case.id))

      expect(last_response).to have_http_status(201)
      expect(run_case.attachments.map(&:filename)).to eq(["screenshot.png"])

      get api_v3_paths.test_management_run_case_attachments(run_case.id)
      expect(json["_embedded"]["elements"].pluck("fileName")).to eq(["screenshot.png"])
    end

    it "uploads run attachments (e.g. the HTML report)" do
      upload_attachment(api_v3_paths.test_management_run_attachments(run.id), name: "playwright-report.zip")

      expect(last_response).to have_http_status(201)
      expect(run.attachments.map(&:filename)).to eq(["playwright-report.zip"])
    end

    context "as an uploader" do
      let(:current) { uploader }

      it "may attach CI artifacts" do
        upload_attachment(api_v3_paths.test_management_run_case_attachments(run_case.id))

        expect(last_response).to have_http_status(201)
      end
    end

    context "as a viewer" do
      let(:current) { viewer }

      it "may list but not upload" do
        get api_v3_paths.test_management_run_case_attachments(run_case.id)
        expect(last_response).to have_http_status(200)

        upload_attachment(api_v3_paths.test_management_run_case_attachments(run_case.id))
        expect_error(403, "MissingPermission")
      end
    end

    it "refuses uploads to a finished run" do
      run.update!(state: "completed", finished_at: Time.current)

      upload_attachment(api_v3_paths.test_management_run_case_attachments(run_case.id))

      expect_error(403, "MissingPermission")
    end
  end
end
