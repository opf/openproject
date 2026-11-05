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

RSpec.describe "Test management run iterations", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs execute_test_runs] })
  end
  shared_let(:tester) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs] })
  end

  let(:run) { create(:tm_test_run, :in_progress, project:) }
  let!(:run_case) { create(:tm_test_run_case, test_run: run, status: "passed") }
  let(:current_user) { manager }
  let(:iterations_path) { "/projects/#{project.identifier}/test_management/test_runs/#{run.id}/iterations" }

  before do
    create(:tm_test_result, run_case:, status: "passed")
    login_as(current_user)
  end

  it "starts a new iteration and shows the history with a switcher" do
    post iterations_path, params: { iteration: { name: "RC 1" } }

    expect(response).to redirect_to(project_test_management_test_run_path(project, run))
    expect(run.reload.iterations.pluck(:number, :name)).to eq([[1, nil], [2, "RC 1"]])
    expect(run_case.reload.status).to eq("untested")

    get project_test_management_test_run_path(project, run)
    body = response.body
    expect(body).to include("tm-run-iteration-label", "tm-run-iteration-switcher", "tm-run-iteration-history")
    expect(body).to include("tm-run-iteration-1", "tm-run-iteration-2", "tm-run-start-iteration")
    expect(body).not_to include("tm-run-past-iteration")
  end

  it "shows a past iteration read-only with its own pass rate" do
    post iterations_path

    get project_test_management_test_run_path(project, run, iteration: 1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("tm-run-past-iteration", "tm-run-back-to-current")
    expect(response.body).to match(/tm-run-iteration-pass-rate-1">\s*100%/)
    expect(response.body).to match(/tm-run-iteration-pass-rate-2">\s*0%/)
  end

  it "falls back to the current iteration for an unknown number" do
    post iterations_path

    get project_test_management_test_run_path(project, run, iteration: 99)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("tm-run-past-iteration")
  end

  context "as a tester" do
    let(:current_user) { tester }

    it "may not start iterations" do
      post iterations_path

      expect(response).to have_http_status(:forbidden)
      expect(run.iterations).to be_empty
    end
  end
end
