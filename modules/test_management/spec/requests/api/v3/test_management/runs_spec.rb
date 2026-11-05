# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "APIv3 test management runs, run cases and imports" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

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

  def json = JSON.parse(last_response.body)

  def post_json(path, body = {})
    post path, body.to_json, { "CONTENT_TYPE" => "application/json" }
  end

  def expect_error(status, identifier)
    expect(last_response).to have_http_status(status)
    expect(json["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{identifier}")
  end

  describe "GET /api/v3/test_management/runs/:id" do
    it "renders the run with counts, pass rate without skipped cases and its run cases" do
      get api_v3_paths.test_management_run(run.id)

      expect(last_response).to have_http_status(200)
      expect(json).to include("_type" => "TestManagementRun", "id" => run.id, "source" => "automation",
                              "externalRef" => run.external_ref, "totalCases" => 3, "passRate" => 50)
      expect(json["statusCounts"]).to include("failed" => 1, "skipped" => 1, "passed" => 1)
      expect(json["runCases"].pluck("id")).to contain_exactly(run_case.id, skipped_case.id, passed_case.id)
      expect(json["_links"]).to include("complete", "cancel", "imports", "iterations")
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
    end

    it "answers 404 for a run case of an invisible project" do
      get api_v3_paths.test_management_run_case(create(:tm_test_run_case).id)

      expect_error(404, "NotFound")
    end
  end

  describe "POST /projects/:id/test_management/runs" do
    let(:collection_path) { api_v3_paths.project_test_management_runs(project.id) }
    let!(:test_case) { create(:tm_test_case, project:) }

    it "creates a run with the given cases (201)" do
      post_json collection_path, { name: "Release check", selectionMode: "specific", caseIds: [test_case.id],
                                   startDate: "2026-11-01" }

      expect(last_response).to have_http_status(201)
      expect(json).to include("_type" => "TestManagementRun", "name" => "Release check", "state" => "new",
                              "selectionMode" => "specific", "startDate" => "2026-11-01", "totalCases" => 1)
      expect(TestManagement::TestRun.find(json["id"]).test_cases).to eq([test_case])
    end

    it "creates an all-cases run with an automation filter" do
      automated = create(:tm_test_case, project:, automated: true)

      post_json collection_path, { name: "Automated", selectionMode: "all", filterOptions: { automation: "automated" } }

      expect(last_response).to have_http_status(201)
      expect(TestManagement::TestRun.find(json["id"]).test_cases).to eq([automated])
    end

    it "answers 422 for invalid values and 403 without add_test_runs" do
      post_json collection_path, { name: "" }
      expect_error(422, "UnprocessableContent")

      login_as(uploader)
      post_json collection_path, { name: "Nope" }
      expect_error(403, "MissingPermission")
    end
  end

  describe "PATCH / DELETE /test_management/runs/:id" do
    let(:path) { api_v3_paths.test_management_run(run.id) }

    def send_json(verb, body = {})
      public_send(verb, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
    end

    it "updates the run (200) and keeps its cases when no selection is sent" do
      send_json(:patch, { name: "Renamed", description: "Notes" })

      expect(last_response).to have_http_status(200)
      expect(json).to include("name" => "Renamed", "description" => "Notes", "totalCases" => 3)
    end

    it "refuses updates of a finished run" do
      run.update!(state: "completed", finished_at: Time.current)

      send_json(:patch, { name: "Late" })

      expect(last_response).to have_http_status(:unprocessable_entity).or have_http_status(:conflict)
      expect(run.reload.name).not_to eq("Late")
    end

    it "deletes the run (204) for users with delete_test_runs" do
      login_as(create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs delete_test_runs] }))

      send_json(:delete)

      expect(last_response).to have_http_status(204)
      expect(TestManagement::TestRun.exists?(run.id)).to be(false)
    end

    it "refuses deleting without delete_test_runs" do
      send_json(:delete)

      expect_error(403, "MissingPermission")
      expect(TestManagement::TestRun.exists?(run.id)).to be(true)
    end
  end

  describe "POST …/reopen" do
    let(:finished) { create(:tm_test_run, :completed, project:) }

    it "reopens a finished run" do
      post_json api_v3_paths.test_management_run_reopen(finished.id)

      expect(last_response).to have_http_status(200)
      expect(json).to include("state" => "in_progress")
      expect(json["_links"]).to include("complete")
    end

    it "answers 409 for an active run" do
      post_json api_v3_paths.test_management_run_reopen(run.id)

      expect_error(409, "UpdateConflict")
    end
  end

  describe "GET /projects/:id/test_management/runs" do
    it "filters by state and name" do
      completed = create(:tm_test_run, :completed, project:, name: "Nightly")

      get "#{api_v3_paths.project_test_management_runs(project.id)}?state=completed&name=nightly"

      expect(json["_embedded"]["elements"].pluck("id")).to eq([completed.id])
    end
  end
end
