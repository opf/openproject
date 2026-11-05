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

RSpec.describe "Test management run case view", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:tester) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:outsider) { create(:user) }

  let(:current_user) { tester }
  let(:run) { create(:tm_test_run, project:, state: "in_progress") }
  let(:test_case) { create(:tm_test_case, :with_steps, project:) }
  let(:run_case) { create(:tm_test_run_case, test_run: run, test_case:, status: "failed") }
  let(:page_path) { project_test_management_test_run_run_case_path(project, run, run_case) }
  let(:xss) { "<script>alert(1)</script>" }
  let(:page) { Capybara.string(response.body) }
  let!(:result) do
    create(:tm_test_result, run_case:, status: "failed", source: "automation",
                            error_message: "Expected receipt #{xss}", error_trace: "Error: boom\n    at pay.spec.ts:9")
  end

  before { login_as(current_user) }

  it "shows the escaped error, the case steps and the result history" do
    get page_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Expected receipt &lt;script&gt;alert(1)&lt;/script&gt;", "at pay.spec.ts:9")
    expect(response.body).not_to include(xss)
    expect(page).to have_css("[data-test-selector='tm-run-case-error']")
    expect(page).to have_css("[data-test-selector='tm-case-steps'] tbody tr", count: 2)
    expect(page).to have_css("[data-test-selector='tm-run-case-result-#{result.id}']")
  end

  it "offers the record form with a status select" do
    get page_path

    expect(page).to have_css("[data-test-selector='tm-run-case-form'] select[name='run_case[status]']")
    expect(page).to have_no_css("[name^='run_case[step_results]']")
  end

  it "records a manual result and returns to the view" do
    patch page_path, params: { return_to: "run_case", run_case: { status: "passed", comment: "Manual retry" } }

    expect(response).to redirect_to(page_path)
    expect(run_case.reload.status).to eq("passed")
    expect(run_case.results.order(:id).last).to have_attributes(status: "passed", comment: "Manual retry", user: tester)
  end

  it "shows the first error line on the run page and links to the details" do
    get project_test_management_test_run_path(project, run)

    expect(response.body).to include("Expected receipt &lt;script&gt;")
    expect(response.body).to include(page_path)
  end

  context "as viewer" do
    let(:current_user) { viewer }

    it "shows the view without the record form and cannot record" do
      get page_path
      expect(response).to have_http_status(:ok)
      expect(page).to have_no_css("[data-test-selector='tm-run-case-form']")

      patch page_path, params: { run_case: { status: "passed" } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "without access" do
    let(:current_user) { outsider }

    it "is not visible" do
      get page_path
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end
end
