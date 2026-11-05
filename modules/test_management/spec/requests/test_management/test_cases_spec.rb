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

RSpec.describe "Test management cases", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases delete_test_cases manage_test_suites]
           })
  end

  let(:page) { Capybara.string(response.body) }

  before { login_as(user) }

  def row_selector(test_case) = "[data-test-selector='tm-case-row-#{test_case.id}']"

  describe "index" do
    it "renders the split pane layout by default" do
      test_case = create(:tm_test_case, project:)

      get project_test_management_test_cases_path(project)

      expect(response).to have_http_status(:ok)
      expect(page).to have_css("[data-folder-tree-layout='split_pane']")
      expect(page).to have_css("[data-test-selector='tm-folder-pane-split']")
      expect(page).to have_css(row_selector(test_case))
    end

    it "hides the split pane tree with the sidebar layout" do
      create(:tm_project_setting, project:, folder_tree_layout: "sidebar")

      get project_test_management_test_cases_path(project)

      expect(page).to have_css("[data-folder-tree-layout='sidebar']")
      expect(page).to have_no_css("[data-test-selector='tm-folder-pane-split']")
    end

    it "lists the cases of subfolders when a parent folder is selected and counts descendants" do
      parent = create(:tm_suite, project:)
      child = create(:tm_suite, project:, parent:)
      direct = create(:tm_test_case, project:, suite: parent)
      nested = create(:tm_test_case, project:, suite: child)
      unfiled = create(:tm_test_case, project:)

      get project_test_management_test_cases_path(project, suite_id: parent.id)

      expect(page).to have_css(row_selector(direct))
      expect(page).to have_css(row_selector(nested))
      expect(page).to have_no_css(row_selector(unfiled))
      expect(page).to have_css("[data-test-selector='tm-folder-#{parent.id}'] .Counter", text: "2")
    end

    it "lists only unfiled cases for the root folder" do
      suite = create(:tm_suite, project:)
      filed = create(:tm_test_case, project:, suite:)
      unfiled = create(:tm_test_case, project:)

      get project_test_management_test_cases_path(project, suite_id: "root")

      expect(page).to have_css(row_selector(unfiled))
      expect(page).to have_no_css(row_selector(filed))
    end

    it "filters by search term, status and priority" do
      match = create(:tm_test_case, project:, title: "Reset password", status: "draft", priority: "high")
      other = create(:tm_test_case, project:, title: "Sign in", status: "ready", priority: "low")

      get project_test_management_test_cases_path(project, q: "password", status: "draft", priority: "high")

      expect(page).to have_css(row_selector(match))
      expect(page).to have_no_css(row_selector(other))
    end

    it "is empty without cases" do
      get project_test_management_test_cases_path(project)

      expect(page).to have_css("[data-test-selector='tm-cases-empty']")
    end

    it "is refused without view_test_cases" do
      login_as(create(:user, member_with_permissions: { project => %i[view_test_runs] }))

      get project_test_management_test_cases_path(project)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "create and update" do
    it "creates a test case with rich-text preconditions and steps" do
      post project_test_management_test_cases_path(project),
           params: { test_case: { title: "Macro case", preconditions: "See ###1 for context", priority: "high",
                                  status: "ready",
                                  steps_attributes: { "0" => { position: 0, action: "Open page",
                                                               expected_result: "Visible" } } } }

      created = TestManagement::TestCase.find_by!(title: "Macro case")
      expect(response).to redirect_to(project_test_management_test_case_path(project, created))
      expect(created.preconditions).to include("###1")
      expect(created.steps.count).to eq(1)
      expect(created.author).to eq(user)
    end

    it "drops blank step rows" do
      post project_test_management_test_cases_path(project),
           params: { test_case: { title: "No steps", priority: "low", status: "draft",
                                  steps_attributes: { "0" => { position: 0, action: "", expected_result: "" } } } }

      expect(TestManagement::TestCase.find_by!(title: "No steps").steps).to be_empty
    end

    it "re-renders the form for an invalid case" do
      post project_test_management_test_cases_path(project),
           params: { test_case: { title: "", priority: "low", status: "ready" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(TestManagement::TestCase.count).to eq(0)
    end

    it "updates a test case, adds a step and records the last editor" do
      test_case = create(:tm_test_case, project:, title: "Before")

      patch project_test_management_test_case_path(project, test_case),
            params: { test_case: { title: "After",
                                   steps_attributes: { "0" => { position: 0, action: "Click", expected_result: "Done" } } } }

      expect(response).to redirect_to(project_test_management_test_case_path(project, test_case))
      expect(test_case.reload).to have_attributes(title: "After", updated_by: user)
      expect(test_case.steps.count).to eq(1)
    end

    it "denies viewers from creating and editing" do
      viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })
      test_case = create(:tm_test_case, project:, title: "Keep")
      login_as(viewer)

      post project_test_management_test_cases_path(project),
           params: { test_case: { title: "Nope", priority: "low", status: "ready" } }
      patch project_test_management_test_case_path(project, test_case), params: { test_case: { title: "Changed" } }

      expect(TestManagement::TestCase.where(title: "Nope")).to be_empty
      expect(test_case.reload.title).to eq("Keep")
    end
  end

  describe "forms" do
    it "renders new and edit with nested step field names" do
      get new_project_test_management_test_case_path(project)
      expect(response.body).to include("test_case[steps_attributes][0][action]", "test_case[steps_attributes][0][data]")

      get edit_project_test_management_test_case_path(project, create(:tm_test_case, project:))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("test_case[steps_attributes][0][action]")
    end

    it "has no assignee or work package fields" do
      get new_project_test_management_test_case_path(project)

      expect(response.body).not_to include("assigned_to_id", "work_package_ids", "label_names")
    end
  end

  describe "show" do
    it "shows who created and last edited the case" do
      test_case = create(:tm_test_case, project:, author: user)
      test_case.update_columns(updated_by_id: user.id)

      get project_test_management_test_case_path(project, test_case)

      expect(page).to have_css("[data-test-selector='tm-case-created-by']", text: user.name)
      expect(page).to have_css("[data-test-selector='tm-case-updated-by']", text: user.name)
    end

    it "shows a dash when the last editor is unknown" do
      get project_test_management_test_case_path(project, create(:tm_test_case, project:, author: user))

      expect(page).to have_css("[data-test-selector='tm-case-updated-by'] .color-fg-muted", text: "—")
    end

    it "renders the overview and runs tabs above the title, one URL per tab" do
      get project_test_management_test_case_path(project, create(:tm_test_case, project:))

      expect(page).to have_css("[data-test-selector='tm-case-tab-overview']")
      expect(page).to have_css("[data-test-selector='tm-case-tab-runs'][href*='tab=runs']")
      expect(page).to have_no_css("[data-test-selector='tm-case-tab-defects']")
      expect(page).to have_no_css("[data-test-selector='tm-case-tab-history']")
      expect(response.body.index("tm-case-tabs")).to be < response.body.index(/PageHeader-title[" ]/)
      expect(page).to have_css("[data-test-selector='tm-case-tab-panel-overview']")
    end

    it "lists the runs that include the case on the runs tab" do
      test_case = create(:tm_test_case, project:)
      run = create(:tm_test_run, project:)
      create(:tm_test_run_case, test_run: run, test_case:)

      get project_test_management_test_case_path(project, test_case, tab: "runs")

      expect(page).to have_css("[data-test-selector='tm-case-run-#{run.id}']")
    end

    it "shows a blankslate on the runs tab without runs" do
      get project_test_management_test_case_path(project, create(:tm_test_case, project:), tab: "runs")

      expect(page).to have_css("[data-test-selector='tm-case-runs-empty']")
    end

    it "falls back to the overview for an unknown tab" do
      get project_test_management_test_case_path(project, create(:tm_test_case, project:), tab: "nope")

      expect(page).to have_css("[data-test-selector='tm-case-tab-panel-overview']")
    end

    it "wires the delete button to the confirmation dialog" do
      test_case = create(:tm_test_case, project:)

      get project_test_management_test_case_path(project, test_case)

      expect(response.body).to include(delete_dialog_project_test_management_test_case_path(project, test_case))
      expect(page).to have_css("[data-controller='async-dialog']")
      expect(page).to have_css("[data-test-selector='tm-case-delete-button']")
    end
  end

  describe "destroy" do
    it "deletes the case and its steps" do
      test_case = create(:tm_test_case, :with_steps, project:)

      delete project_test_management_test_case_path(project, test_case)

      expect(response).to redirect_to(project_test_management_test_cases_path(project))
      expect(TestManagement::TestCase.exists?(test_case.id)).to be(false)
    end

    it "is refused without delete_test_cases" do
      editor = create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] })
      test_case = create(:tm_test_case, project:)
      login_as(editor)

      delete project_test_management_test_case_path(project, test_case)

      expect(TestManagement::TestCase.exists?(test_case.id)).to be(true)
    end
  end
end
