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

RSpec.describe "Test management runs", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs execute_test_runs] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  let(:current_user) { manager }
  let(:page) { Capybara.string(response.body) }

  before { login_as(current_user) }

  def selector(name) = "[data-test-selector='#{name}']"

  describe "GET index" do
    let!(:active) { create(:tm_test_run, project:) }
    let!(:done) { create(:tm_test_run, :completed, project:) }
    let!(:dropped) { create(:tm_test_run, :cancelled, project:) }

    before do
      create(:tm_test_run_case, test_run: done, status: "passed")
      create(:tm_test_run_case, test_run: done, status: "failed")
    end

    it "shows active runs by default with filter tabs and a new run button" do
      get project_test_management_test_runs_path(project)

      expect(response).to have_http_status(:ok)
      expect(page).to have_css(selector("tm-run-row-#{active.id}"))
      expect(page).to have_no_css(selector("tm-run-row-#{done.id}"))
      %w[active completed cancelled all].each { |filter| expect(page).to have_css(selector("tm-run-filter-#{filter}")) }
      expect(page).to have_css(selector("tm-new-run"))
    end

    it "filters completed runs and shows progress and pass rate" do
      get project_test_management_test_runs_path(project, filter: "completed")

      expect(page).to have_css(selector("tm-run-row-#{done.id}"))
      expect(page).to have_no_css(selector("tm-run-row-#{active.id}"))
      expect(page).to have_css("#{selector("tm-run-row-#{done.id}")} .tm-run-progress")
      expect(page).to have_css(selector("tm-run-passed-#{done.id}"), text: "50%")
    end

    it "lists every run under all" do
      get project_test_management_test_runs_path(project, filter: "all")

      [active, done, dropped].each { |run| expect(page).to have_css(selector("tm-run-row-#{run.id}")) }
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "has no new run button" do
        get project_test_management_test_runs_path(project)

        expect(page).to have_no_css(selector("tm-new-run"))
      end
    end
  end

  describe "new / create" do
    let(:suite) { create(:tm_suite, project:) }
    let!(:test_case) { create(:tm_test_case, project:, suite:) }

    it "renders the form with the all and specific selection options" do
      get new_project_test_management_test_run_path(project)

      expect(response).to have_http_status(:ok)
      expect(page).to have_css("#test_run_selection_mode_all")
      expect(page).to have_css("#test_run_selection_mode_specific")
      expect(page).to have_no_css("#test_run_selection_mode_dynamic")
      expect(page).to have_css(selector("tm-run-change-selection"))
      expect(page).to have_css("[data-test-selector='tm-run-selection-tree'] input[value='#{test_case.id}']", visible: :all)
      expect(response.body).not_to match(/\son[a-z]+="/)
    end

    it "re-renders with the applied selection without saving" do
      post project_test_management_test_runs_path(project),
           params: { refresh_selection: "1",
                     test_run: { name: "Draft", selection_mode: "specific", selection_submitted: "1",
                                 selection_suite_ids: [suite.id] } }

      expect(response).to have_http_status(:ok)
      expect(page).to have_css(selector("tm-run-selected-count"))
      expect(TestManagement::TestRun.count).to eq(0)
    end

    it "creates a run with selected cases and redirects to the show page" do
      post project_test_management_test_runs_path(project),
           params: { test_run: { name: "Checkout run", selection_mode: "specific", selection_submitted: "1",
                                 assigned_to_id: manager.id, test_case_ids: [test_case.id] } }

      run = TestManagement::TestRun.last
      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(page).to have_css(selector("tm-run-title"), text: "Checkout run")
      expect(run.test_cases).to eq([test_case])
      expect(run.run_cases.first.assigned_to).to eq(manager)
    end

    it "creates an all-cases run with an automation filter" do
      automated = create(:tm_test_case, project:, automated: true)

      post project_test_management_test_runs_path(project),
           params: { test_run: { name: "Automated", selection_mode: "all", selection_submitted: "1",
                                 filter_options: { automation: "automated" } } }

      expect(TestManagement::TestRun.last.test_cases).to eq([automated])
    end

    context "as admin" do
      let(:current_user) { create(:admin) }

      it "renders show after create with admin header actions" do
        post project_test_management_test_runs_path(project),
             params: { test_run: { name: "Admin run", selection_mode: "specific", selection_submitted: "1",
                                   test_case_ids: [test_case.id] } }

        follow_redirect!

        expect(response).to have_http_status(:ok)
        expect(page).to have_css(selector("tm-run-ci-trigger"), visible: :all)
        expect(page).to have_css(selector("tm-run-delete"), visible: :all)
        expect(page).to have_no_css(selector("tm-run-export-menu"), visible: :all)
      end
    end

    it "re-renders the form on errors" do
      post project_test_management_test_runs_path(project), params: { test_run: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(TestManagement::TestRun.count).to eq(0)
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "is forbidden" do
        post project_test_management_test_runs_path(project), params: { test_run: { name: "x" } }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET show" do
    let(:root) { create(:tm_suite, project:) }
    let(:child) { create(:tm_suite, project:, parent: root) }
    let(:run) { create(:tm_test_run, :in_progress, project:) }
    let!(:run_case) do
      create(:tm_test_run_case, test_run: run, status: "passed",
                                test_case: create(:tm_test_case, project:, suite: child))
    end

    it "shows the summary, collapsible sections and grouped cases with menus" do
      get project_test_management_test_run_path(project, run)

      expect(response).to have_http_status(:ok)
      expect(page).to have_css(selector("tm-run-id"), text: run.formatted_id)
      expect(page).to have_css(selector("tm-run-pass-rate"), text: "100%")
      expect(page).to have_css(selector("tm-run-statistics"))
      expect(page).to have_css("#{selector("tm-run-group-#{root.id}")} #{selector("tm-run-group-#{child.id}")}")
      expect(page).to have_css(selector("tm-run-case-#{run_case.id}"))
      expect(page).to have_css("[name='run_case[status]']", visible: :all)
      expect(page).to have_css("[name='run_case[assigned_to_id]']", visible: :all)
      expect(page).to have_css(selector("tm-run-complete"))
      expect(page).to have_css(selector("tm-run-cancel"))
      expect(response.body).to include(complete_dialog_project_test_management_test_run_path(project, run),
                                       cancel_dialog_project_test_management_test_run_path(project, run))
      expect(page).to have_css("[data-controller='async-dialog']")
    end

    it "shows no pie chart" do
      get project_test_management_test_run_path(project, run)

      expect(page).to have_no_css(selector("tm-run-pie"))
      expect(page).to have_css(".tm-run-progress")
    end

    it "opens the complete and cancel confirmation dialogs" do
      get complete_dialog_project_test_management_test_run_path(project, run),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("tm-run-complete-dialog")

      get cancel_dialog_project_test_management_test_run_path(project, run), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-run-cancel-dialog")
    end

    it "denies the complete dialog without manage permission" do
      login_as(viewer)

      get complete_dialog_project_test_management_test_run_path(project, run),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:forbidden)
    end

    it "is read-only for a finished run" do
      run.update!(state: "completed")

      get project_test_management_test_run_path(project, run)

      expect(page).to have_no_css("[name='run_case[status]']", visible: :all)
      expect(page).to have_css(selector("tm-run-frozen"))
      expect(page).to have_css(selector("tm-run-reopen"))
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "shows statuses without menus or actions" do
        get project_test_management_test_run_path(project, run)

        expect(page).to have_no_css("[name='run_case[status]']", visible: :all)
        expect(page).to have_no_css(selector("tm-run-complete"))
      end
    end

    it "shows the latest result of each case, and of the shown past iteration" do
      first = create(:tm_test_run_iteration, test_run: run, number: 1)
      create(:tm_test_result, run_case:, status: "failed", error_message: "Old failure", iteration: first)
      create(:tm_test_run_iteration, test_run: run, number: 2)
      create(:tm_test_result, run_case:, status: "passed")

      get project_test_management_test_run_path(project, run)
      expect(response.body).not_to include("Old failure")

      get project_test_management_test_run_path(project, run, iteration: 1)
      expect(response.body).to include("Old failure")
    end

    it "404s for a run of another project" do
      get project_test_management_test_run_path(project, create(:tm_test_run))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "edit / update" do
    let(:run) { create(:tm_test_run, project:, name: "Old") }

    it "renders the edit form" do
      get edit_project_test_management_test_run_path(project, run)

      expect(response.body).to include('value="Old"')
    end

    it "updates the run" do
      patch project_test_management_test_run_path(project, run), params: { test_run: { name: "New" } }

      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      expect(run.reload.name).to eq("New")
    end
  end

  describe "transitions" do
    let(:run) { create(:tm_test_run, :in_progress, project:) }
    let!(:run_case) { create(:tm_test_run_case, test_run: run, status: "failed") }

    it "completes, then reopens" do
      post complete_project_test_management_test_run_path(project, run)
      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      expect(run.reload.state).to eq("completed")
      expect(run_case.reload.final_status).to eq("failed")

      post reopen_project_test_management_test_run_path(project, run)
      expect(run.reload.state).to eq("in_progress")
    end

    it "cancels" do
      post cancel_project_test_management_test_run_path(project, run)

      expect(run.reload.state).to eq("cancelled")
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "cannot complete" do
        post complete_project_test_management_test_run_path(project, run)

        expect(response).to have_http_status(:forbidden)
        expect(run.reload.state).to eq("in_progress")
      end
    end
  end

  describe "DELETE destroy" do
    let!(:run) { create(:tm_test_run, project:) }
    let(:deleter) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs delete_test_runs] }) }

    it "deletes the run when permitted" do
      login_as(deleter)

      delete project_test_management_test_run_path(project, run)

      expect(response).to redirect_to(project_test_management_test_runs_path(project))
      expect(TestManagement::TestRun.find_by(id: run.id)).to be_nil
    end

    it "forbids viewers" do
      login_as(viewer)

      delete project_test_management_test_run_path(project, run)

      expect(response).to have_http_status(:forbidden)
      expect(TestManagement::TestRun.find_by(id: run.id)).to be_present
    end
  end
end
