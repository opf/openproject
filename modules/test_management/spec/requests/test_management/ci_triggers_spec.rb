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

RSpec.describe "Test management Run in CI (UI)", :disable_ssrf_filter, :skip_csrf, :webmock, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:trigger_user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation manage_test_ci]
           })
  end
  shared_let(:runner) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs] }) }
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:automated) do
    create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item")
  end
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:, name: "E2E") }

  let(:current_user) { trigger_user }
  let(:triggers_path) { "/projects/#{project.identifier}/test_management/ci_triggers" }
  let(:dispatch_url) { "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches" }

  before { login_as(current_user) }

  it "shows the form for a folder with the automated case count" do
    get "#{triggers_path}/new", params: { suite_id: suite.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("tm-ci-trigger-form", "Checkout", "E2E")
    expect(response.body).not_to include("ghp_trigger_secret")
  end

  it "triggers, redirects to the pre-created run and shows the trigger on the run page" do
    stub_request(:post, dispatch_url).to_return(
      status: 200, body: { workflow_run_id: 5, html_url: "https://github.com/my-org/shop/actions/runs/5" }.to_json
    )

    post triggers_path, params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id, mode: "new_run", ref: "" } }

    run = TestManagement::TestRun.where(project_id: project.id).sole
    expect(response).to redirect_to("/projects/#{project.identifier}/test_management/test_runs/#{run.id}")
    expect(flash[:notice]).to be_present

    get "/projects/#{project.identifier}/test_management/test_runs/#{run.id}"
    expect(response.body).to include("tm-run-ci-trigger-status", "https://github.com/my-org/shop/actions/runs/5")
  end

  it "keeps the run and flashes the provider error" do
    stub_request(:post, dispatch_url).to_return(status: 404, body: { message: "Not Found" }.to_json)

    post triggers_path, params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id } }

    expect(response).to have_http_status(:see_other)
    expect(flash[:error]).to include("HTTP 404: Not Found")
    expect(TestManagement::TestRun.where(project_id: project.id).sole.ci_trigger_status).to eq("failed")
  end

  it "re-renders the form on invalid input" do
    post triggers_path, params: { ci_trigger: { suite_id: suite.id, connection_id: connection.id, ref: "bad ref;" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("tm-ci-trigger-form")
    expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
  end

  context "without trigger_test_automation" do
    let(:current_user) { runner }

    it "is forbidden and hides the buttons" do
      get "#{triggers_path}/new", params: { suite_id: suite.id }
      expect(response).to have_http_status(:forbidden)

      get "/projects/#{project.identifier}/test_management/test_cases/#{automated.id}"
      expect(response.body).not_to include("tm-case-ci-trigger")
    end
  end

  it "shows Run in CI on an automated case and on a folder" do
    get "/projects/#{project.identifier}/test_management/test_cases/#{automated.id}"
    expect(response.body).to include("tm-case-ci-trigger")

    get "/projects/#{project.identifier}/test_management/test_cases", params: { suite_id: suite.id }
    expect(response.body).to include("tm-folder-ci-trigger")
  end
end
