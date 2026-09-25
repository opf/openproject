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
  include Workflows::EditHelpers
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
    other_type.default_variant.workflow.update!(name: "Standard flow", description: "How the company works")
    create(:workflow,
           workflow: other_type.default_variant.workflow,
           role:,
           old_status: status_a,
           new_status: status_b)
  end

  before { login_as admin }

  it "points the type at an existing workflow through the picker" do
    visit edit_type_workflow_path(type_id: type.id)

    within_test_selector("workflow-selector") { expect(page).to have_text("Bug") }

    switch_workflow_to "Standard flow"

    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(variant.reload.workflow).to eq(shared_workflow)

    within_test_selector("workflow-selector") { expect(page).to have_text("Standard flow") }
  end

  describe "picking a workflow that lacks statuses the current one uses" do
    let(:status_closed) { create(:status, name: "Closed") }
    let(:other_role) { create(:project_role) }
    let(:confirm_dialog) { find_test_selector("change-workflow-confirm-dialog") }

    before do
      create(:status_transition, workflow: variant.workflow, role:, old_status: status_a, new_status: status_b)
      create(:status_transition, workflow: variant.workflow, role:, old_status: status_b, new_status: status_closed)
      create(:status_transition, workflow: variant.workflow, role: other_role, old_status: status_b, new_status: status_closed)
      create(:status_transition,
             workflow: variant.workflow, role: create(:work_package_role), old_status: status_b, new_status: status_closed)
    end

    it "lists the statuses that get lost and assigns only once confirmed" do
      previous = variant.workflow
      visit edit_type_workflow_path(type_id: type.id)

      switch_workflow_to "Standard flow"

      within(confirm_dialog) do
        expect(page).to have_text("Use a different workflow for Bug?")
        expect(page).to have_text("The following statuses don’t exist in the workflow you have selected (\"Standard flow\"):")

        within_test_selector("change-workflow-missing-statuses") do
          expect(page).to have_css("span.text-bold", text: "Closed")
          expect(page).to have_text("2 transitions for 2 roles")
          expect(page).to have_no_text("In progress")
        end

        expect(page).to have_text("Existing work packages with these statuses will not be affected.")
        click_on I18n.t(:button_cancel)
      end

      expect(page).to have_no_test_selector("change-workflow-confirm-dialog")
      expect(variant.reload.workflow).to eq(previous)

      switch_workflow_to "Standard flow"
      within(confirm_dialog) { click_on I18n.t(:button_confirm) }

      expect(page).to have_text(I18n.t(:notice_successful_update))
      expect(variant.reload.workflow).to eq(shared_workflow)
    end

    it "says every transition goes when the picked workflow has none, without listing the statuses" do
      create(:named_workflow, name: "Empty flow")
      visit edit_type_workflow_path(type_id: type.id)

      switch_workflow_to "Empty flow"

      within(confirm_dialog) do
        expect(page).to have_text("Use a different workflow for Bug?")
        expect(page).to have_text("The workflow you have selected (\"Empty flow\") has no transitions. " \
                                  "All status transitions of Bug will be removed.")
        expect(page).to have_no_test_selector("change-workflow-missing-statuses")

        click_on I18n.t(:button_confirm)
      end

      expect(page).to have_text(I18n.t(:notice_successful_update))
      expect(variant.reload.workflow.name).to eq("Empty flow")
    end
  end

  it "asks for the name before it creates, then opens the workflow's own page" do
    visit edit_type_workflow_path(type_id: type.id)

    open_workflow_create_dialog

    within_dialog I18n.t("workflows.form.new_title") do
      expect(page).to have_field("Workflow name", with: "Bug workflow (2)")

      fill_in "Workflow name", with: "Bug specific flow"
      click_on I18n.t(:button_create)
    end

    expect(page).to have_current_path(%r{/workflows/\d+/edit})
    expect(page).to have_css(".PageHeader-title", text: "Bug specific flow")

    expect(variant.reload.workflow.name).to eq("Bug specific flow")
  end

  it "copies the transitions of the workflow the dialog started from" do
    visit edit_type_workflow_path(type_id: type.id)

    open_workflow_create_dialog(start: "copy") do
      select_autocomplete(find_test_selector("workflow-copy-source"),
                          query: "Standard",
                          results_selector: "#workflow-dialog")
    end

    within_dialog I18n.t("workflows.form.new_title") do
      fill_in "Workflow name", with: "Bug specific flow"
      click_on I18n.t(:button_create)
    end

    expect(page).to have_current_path(%r{/workflows/\d+/edit})
    expect(variant.reload.workflow.status_transitions.pluck(:old_status_id, :new_status_id))
      .to contain_exactly([status_a.id, status_b.id])
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

      open_workflow_picker

      within_test_selector("workflow-panel") do
        expect(page).to have_link("Company flow")
        expect(page).to have_link("Bookshop flow")
        expect(page).to have_no_link("Foundry flow")
      end
    end

    it "assigns the project's own workflow" do
      visit tab_path

      switch_workflow_to "Bookshop flow"

      expect(page).to have_text(I18n.t(:notice_successful_update))
      expect(owned_variant.reload.workflow).to eq(ours)
    end

    it "leaves starting a workflow to administration" do
      visit tab_path

      expect(page).to have_test_selector("workflow-selector")
      expect(page).to have_no_test_selector("workflow-create-new")
    end
  end

  it "offers administration no workflow any project owns" do
    create(:project_owned_workflow, project: create(:project, name: "Bookshop"), name: "Bookshop flow")

    visit edit_type_workflow_path(type_id: type.id)

    open_workflow_picker

    within_test_selector("workflow-panel") do
      expect(page).to have_link("Standard flow")
      expect(page).to have_text("How the company works")
      expect(page).to have_no_link("Bookshop flow")
    end
  end
end
