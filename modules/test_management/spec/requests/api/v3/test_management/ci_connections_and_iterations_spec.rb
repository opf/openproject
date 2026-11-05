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

RSpec.describe "APIv3 test management CI connections and run iterations" do
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
  shared_let(:case_a) { create(:tm_test_case, project:, title: "Checkout") }

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

  describe "CI connections" do
    let!(:connection) do
      create(:tm_ci_connection, :new_iteration, project:, name: "Shop", repository: "my-org/shop",
                                                token: "ghp_secret_token_value")
    end

    it "lists and shows connections without the token" do
      get api_v3_paths.project_test_management_ci_connections(project.id)

      expect(last_response).to have_http_status(200)
      element = json["_embedded"]["elements"].sole
      expect(element).to include("_type" => "TestManagementCiConnection", "name" => "Shop", "provider" => "github",
                                 "repository" => "my-org/shop", "ingestMode" => "new_iteration",
                                 "targetRunName" => "Smoke", "tokenSet" => true)
      expect(last_response.body).not_to include("ghp_secret_token_value")
      expect(last_response.body).not_to include(connection.token_ciphertext)
      expect(element.keys.grep(/token/i)).to contain_exactly("tokenSet")

      get api_v3_paths.test_management_ci_connection(connection.id)
      expect(last_response).to have_http_status(200)
      expect(json["_links"]["repository"]["href"]).to eq("https://github.com/my-org/shop")
    end

    it "is visible to uploaders but not to plain viewers" do
      login_as(uploader)
      get api_v3_paths.project_test_management_ci_connections(project.id)
      expect(last_response).to have_http_status(200)

      login_as(viewer)
      get api_v3_paths.project_test_management_ci_connections(project.id)
      expect_error(403, "MissingPermission")

      get api_v3_paths.test_management_ci_connection(connection.id)
      expect_error(404, "NotFound")
    end
  end

  describe "iterations" do
    let(:run) { create(:tm_test_run, :in_progress, project:) }
    let!(:run_case) { create(:tm_test_run_case, test_run: run, test_case: case_a, status: "passed") }

    before { create(:tm_test_result, run_case:, status: "passed") }

    it "starts an iteration (201), lists the history and shows one iteration" do
      post_json api_v3_paths.test_management_run_iterations(run.id), { name: "RC 1" }

      expect(last_response).to have_http_status(201)
      expect(json).to include("_type" => "TestManagementRunIteration", "number" => 2, "name" => "RC 1",
                              "current" => true, "passRate" => 0)

      get api_v3_paths.test_management_run_iterations(run.id)
      expect(json["_embedded"]["elements"].map { |e| [e["number"], e["current"], e["passRate"]] })
        .to eq([[1, false, 100], [2, true, 0]])

      get api_v3_paths.test_management_run_iteration(run.id, 1)
      expect(json).to include("number" => 1)
      expect(json["statusCounts"]).to include("passed" => 1)

      get api_v3_paths.test_management_run(run.id)
      expect(json).to include("currentIteration" => 2, "iterationsCount" => 2)
      expect(json["_links"]).to include("iterations")
    end

    it "answers 404 for an unknown iteration, 403 without add_test_runs and 409 for a finished run" do
      get api_v3_paths.test_management_run_iteration(run.id, 9)
      expect_error(404, "NotFound")

      login_as(uploader)
      post_json api_v3_paths.test_management_run_iterations(run.id)
      expect_error(403, "MissingPermission")

      login_as(manager)
      run.update_columns(state: "completed", finished_at: Time.current)
      post_json api_v3_paths.test_management_run_iterations(run.id)
      expect_error(409, "UpdateConflict")
    end
  end

  describe "ingest in new_iteration mode" do
    let(:current) { uploader }

    def ingest(body)
      post_json api_v3_paths.project_test_management_automation_results(project.id), body
    end

    it "reports the iteration, mode and connection" do
      connection = create(:tm_ci_connection, :new_iteration, project:, name: "Shop", repository: "my-org/shop")
      ci = { provider: "github", repository: "my-org/shop" }

      ingest(externalRef: "gh:1", ci:, tests: [{ caseId: case_a.id, status: "passed" }])
      expect(last_response).to have_http_status(201)
      expect(json).to include("createdRun" => true, "createdIteration" => true, "mode" => "new_iteration")
      expect(json["iteration"]).to include("number" => 1)
      expect(json["_links"]["connection"]["href"]).to eq(api_v3_paths.test_management_ci_connection(connection.id))
      expect(json["run"]).to include("name" => "Smoke", "currentIteration" => 1)

      ingest(externalRef: "gh:2", ci:, tests: [{ caseId: case_a.id, status: "failed" }])
      expect(last_response).to have_http_status(200)
      expect(json).to include("createdRun" => false, "createdIteration" => true)
      expect(json["iteration"]).to include("number" => 2)
      expect(json["import"]).to include("iteration" => 2, "externalRef" => "gh:2")
    end
  end
end
