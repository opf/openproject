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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Choosing the workflow a type uses", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status, name: "New") }
  shared_let(:status_b) { create(:status, name: "In progress") }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:other_type) { create(:type, name: "Feature") }

  let(:variant) { type.default_variant }
  let(:shared_workflow) { other_type.default_variant.workflow }

  before_all do
    other_type.default_variant.workflow.update!(name: "Standard flow")
    create(:workflow,
           workflow: other_type.default_variant.workflow,
           role:,
           old_status: status_a,
           new_status: status_b)
  end

  before { login_as admin }

  it "points the type at an existing workflow and says who else uses it" do
    visit edit_type_workflow_path(type_id: type.id)

    within_test_selector("workflow-reuse-mode") { expect(page).to have_text("Independent configuration") }

    within_test_selector("workflow-reuse-mode") { click_on "Change workflow" }

    within_dialog "Change workflow" do
      select_autocomplete(find_test_selector("change-workflow-select"),
                          query: "Standard",
                          results_selector: "body")
      click_on "Save"
    end

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(variant.reload.workflow).to eq(shared_workflow)

    within_test_selector("workflow-reuse-mode") do
      expect(page).to have_css("h3", text: "Reuses workflow Standard flow")
      expect(page).to have_link("Standard flow")
    end

    within_test_selector("workflow-usage-box") do
      expect(page).to have_text("Used in 1 other place")
      expect(page).to have_link("Feature")
    end
  end

  it "creates a new workflow from the tab and assigns it to the type" do
    visit edit_type_workflow_path(type_id: type.id)

    within_test_selector("workflow-reuse-mode") { click_on "Create new workflow" }

    within_dialog "Create workflow" do
      fill_in "Workflow name", with: "Bug specific flow"
      click_on "Create"
    end

    expect(page).to have_current_path(edit_type_workflow_path(type_id: type.id))
    expect(variant.reload.workflow.name).to eq("Bug specific flow")

    within_test_selector("workflow-reuse-mode") do
      expect(page).to have_text("Independent configuration")
      expect(page).to have_link("Bug specific flow")
    end

    within_test_selector("workflow-usage-box") { expect(page).to have_text("Not used anywhere else") }
  end

  describe "inside a project" do
    shared_let(:project) { create(:project, name: "Bookshop", types: [type]) }
    shared_let(:other_project) { create(:project, name: "Foundry") }

    # Named here rather than taken from the type: the examples above reassign the type's own
    # workflow, leaving the shared type carrying an id their rollback has already removed.
    shared_let(:global_flow) { create(:named_workflow, name: "Company flow") }

    shared_let(:owned_variant) do
      create(:project_owned_type_variant, type:, project:, variant_name: "Internal", workflow: global_flow)
    end
    shared_let(:project_admin) do
      create(:user, member_with_permissions: { project => %i[manage_project_variants] })
    end

    shared_let(:ours) { create(:project_owned_workflow, project:, name: "Bookshop flow") }
    shared_let(:theirs) { create(:project_owned_workflow, project: other_project, name: "Foundry flow") }

    let(:tab_path) do
      edit_type_workflow_path(in_project_id: project, type_id: type.id, variant_id: owned_variant.id)
    end

    before { login_as project_admin }

    it "offers the global workflows and the project's own, and nothing another project owns" do
      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Change workflow" }

      within_dialog "Change workflow" do
        find_test_selector("change-workflow-select").find(".ng-arrow-wrapper").click

        expect(page).to have_css(".ng-option", text: "Company flow")
        expect(page).to have_css(".ng-option", text: "Bookshop flow")
        expect(page).to have_no_css(".ng-option", text: "Foundry flow")
      end
    end

    it "assigns the project's own workflow" do
      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Change workflow" }

      within_dialog "Change workflow" do
        select_autocomplete(find_test_selector("change-workflow-select"),
                            query: "Bookshop",
                            results_selector: "body")
        click_on "Save"
      end

      expect(page).to have_text(I18n.t(:notice_successful_update))
      expect(owned_variant.reload.workflow).to eq(ours)
    end

    it "creates a workflow the project owns and assigns it" do
      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Create new workflow" }

      within_dialog "Create workflow" do
        fill_in "Workflow name", with: "Internal flow"
        click_on "Create"
      end

      expect(page).to have_current_path(tab_path)

      created = owned_variant.reload.workflow
      expect(created.name).to eq("Internal flow")
      expect(created.project).to eq(project)
    end
  end

  it "offers administration no workflow any project owns" do
    create(:project_owned_workflow, project: create(:project, name: "Bookshop"), name: "Bookshop flow")

    visit edit_type_workflow_path(type_id: type.id)

    within_test_selector("workflow-reuse-mode") { click_on "Change workflow" }

    within_dialog "Change workflow" do
      find_test_selector("change-workflow-select").find(".ng-arrow-wrapper").click

      expect(page).to have_css(".ng-option", text: "Standard flow")
      expect(page).to have_no_css(".ng-option", text: "Bookshop flow")
    end
  end
end
