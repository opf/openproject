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

RSpec.describe "APIv3 test management Run in CI", :disable_ssrf_filter, :webmock do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, identifier: "shop-api", enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:runner) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs] }) }
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/a.spec.ts#pays") }
  shared_let(:connection) do
    create(:tm_ci_connection, :github_trigger, project:, name: "Pipelines")
  end

  let(:path) { api_v3_paths.project_test_management_ci_triggers(project.id) }
  let(:dispatch_url) { "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches" }

  before { login_as(trigger_user) }

  def json = JSON.parse(last_response.body)

  def post_json(body)
    post path, body.to_json, { "CONTENT_TYPE" => "application/json" }
  end

  it "pre-creates the run, triggers the pipeline and answers 201" do
    stub_request(:post, dispatch_url).to_return(status: 200,
                                                body: { workflow_run_id: 77,
                                                        html_url: "https://github.com/my-org/shop/actions/runs/77" }.to_json)

    post_json(connection: "Pipelines", testCaseId: automated.id, ref: "main")

    expect(last_response).to have_http_status(201)
    run = TestManagement::TestRun.where(project_id: project.id).sole
    expect(json).to include("_type" => "TestManagementCiTrigger", "status" => "triggered", "runId" => run.id,
                            "iterationId" => run.current_iteration.id, "iterationNumber" => 1, "ref" => "main",
                            "grep" => "pays", "url" => "https://github.com/my-org/shop/actions/runs/77", "externalId" => "77")
    expect(json["_links"]["run"]["href"]).to eq(api_v3_paths.test_management_run(run.id))
    expect(last_response.body).not_to include("ghp_trigger_secret")

    get api_v3_paths.test_management_run(run.id)
    expect(json["ciTrigger"]).to include("status" => "triggered", "url" => "https://github.com/my-org/shop/actions/runs/77")
  end

  it "answers 502 with the error when the provider refuses" do
    stub_request(:post, dispatch_url).to_return(status: 422, body: { message: "No ref found" }.to_json)

    post_json(connection: connection.id.to_s, suiteId: suite.id, ref: "nope")

    expect(last_response).to have_http_status(502)
    expect(json).to include("status" => "failed", "error" => "HTTP 422: No ref found")
  end

  it "adds an iteration to an existing run" do
    stub_request(:post, dispatch_url).to_return(status: 204)
    run = create(:tm_test_run, project:)
    run.add_cases!([automated])

    post_json(connection: "Pipelines", mode: "new_iteration", runId: run.id)

    expect(last_response).to have_http_status(201)
    expect(json["runId"]).to eq(run.id)
  end

  it "validates the request" do
    post_json(connection: "unknown", suiteId: suite.id)
    expect(last_response).to have_http_status(422)

    post_json(connection: "Pipelines")
    expect(last_response).to have_http_status(422)

    post_json(connection: "Pipelines", suiteId: 0)
    expect(last_response).to have_http_status(404)
  end

  it "answers 403 while CI is switched off" do
    create(:tm_project_setting, project:, options: { "enable_ci" => false })

    post_json(connection: "Pipelines", suiteId: suite.id)

    expect(last_response).to have_http_status(403)
    expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
  end

  it "needs trigger_test_automation" do
    login_as(runner)
    post_json(connection: "Pipelines", suiteId: suite.id)
    expect(last_response).to have_http_status(403)
  end
end
