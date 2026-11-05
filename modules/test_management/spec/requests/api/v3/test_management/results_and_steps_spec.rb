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

RSpec.describe "APIv3 test management case-level results" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:tester) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs upload_test_results] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { tester }
  let(:run) { create(:tm_test_run, project:, state: "in_progress") }
  let(:run_case) { create(:tm_test_run_case, test_run: run, test_case: create(:tm_test_case, project:)) }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def post_json(path, body)
    header "Content-Type", "application/json"
    post path, body.to_json
  end

  describe "POST run_cases/:id/results" do
    let(:path) { api_v3_paths.test_management_run_case_results(run_case.id) }

    it "records a manual result (201), updates the run case and starts the run" do
      post_json(path, { status: "failed", comment: "manual" })

      expect(last_response).to have_http_status(:created)
      expect(json).to include("_type" => "TestManagementResult", "status" => "failed", "comment" => "manual",
                              "source" => "manual")
      expect(run_case.reload.status).to eq("failed")
      expect(run.reload.state).to eq("in_progress")
    end

    it "rejects empty requests and unknown statuses" do
      post_json(path, {})
      expect(last_response).to have_http_status(:unprocessable_entity)

      post_json(path, { status: "great" })
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

  describe "GET results/:id and run case" do
    let!(:result) do
      create(:tm_test_result, run_case:, status: "failed", error_message: "boom", error_trace: "Error: boom\n at x")
    end

    it "returns the error" do
      get api_v3_paths.test_management_result(result.id)

      expect(last_response).to have_http_status(:ok)
      expect(json).to include("errorMessage" => "boom", "errorTrace" => "Error: boom\n at x")
      expect(json.dig("_links", "runCase", "href")).to eq(api_v3_paths.test_management_run_case(run_case.id))
    end

    it "embeds the results in the run case" do
      get api_v3_paths.test_management_run_case(run_case.id)

      expect(json["results"].last).to include("errorMessage" => "boom", "status" => "failed")
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
end
