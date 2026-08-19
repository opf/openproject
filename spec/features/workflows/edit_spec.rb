# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe "Workflow edit", :js do
  include Toasts::Expectations
  include Workflows::EditHelpers

  let(:role) { create(:project_role) }
  let(:type) { create(:type) }
  let(:admin)  { create(:admin) }
  let(:statuses) { (1..3).map { create(:status) } }
  let!(:workflow) do
    create(:workflow, role_id: role.id,
                      type_id: type.id,
                      old_status_id: statuses[0].id,
                      new_status_id: statuses[1].id,
                      author: false,
                      assignee: false)
  end

  current_user { admin }

  before do
    visit_workflow_edit
  end

  it "allows adding another workflow" do
    visit_workflow_edit(roles: [role])

    check workflow_checkbox(1, 0)

    click_button "Save"

    expect_flash(message: "Successful update.")

    expect(page)
      .to have_field workflow_checkbox(0, 1), checked: true
    expect(page)
      .to have_field workflow_checkbox(1, 0), checked: true

    expect(Workflow.where(type_id: type.id, role_id: role.id).count).to be 2

    w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[0].id, new_status_id: statuses[1].id).first
    assert !w.author
    assert !w.assignee

    w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[1].id, new_status_id: statuses[0].id).first
    assert !w.author
    assert !w.assignee
  end

  it "allows editing the workflow when the user is author" do
    create(:workflow, role_id: role.id, type_id: type.id,
                      old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                      author: true, assignee: false)

    visit_workflow_edit(roles: [role], tab: "author")

    within "#workflow_form_author" do
      check workflow_checkbox(1, 0)
    end

    click_button "Save"

    expect_flash(message: "Successful update.")

    within "#workflow_form_author" do
      expect(page)
        .to have_field workflow_checkbox(0, 1), checked: true
      expect(page)
        .to have_field workflow_checkbox(1, 0), checked: true

      expect(Workflow.where(type_id: type.id, role_id: role.id, author: true).count).to be 2

      # the newly added Workflow
      w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[1].id, new_status_id: statuses[0].id).first
      assert w.author
      assert !w.assignee

      # The always workflow is unchanged
      w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                         author: false).first
      assert !w.author
      assert !w.assignee
    end
  end

  it "allows editing the workflow when the user is assignee" do
    create(:workflow, role_id: role.id, type_id: type.id,
                      old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                      author: false, assignee: true)

    visit_workflow_edit(roles: [role], tab: "assignee")

    within "#workflow_form_assignee" do
      check workflow_checkbox(1, 0)
    end

    click_button "Save"

    expect_flash(message: "Successful update.")

    within "#workflow_form_assignee" do
      expect(page)
        .to have_field workflow_checkbox(0, 1), checked: true
      expect(page)
        .to have_field workflow_checkbox(1, 0), checked: true

      expect(Workflow.where(type_id: type.id, role_id: role.id, assignee: true).count).to be 2

      # the newly added Workflow
      w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[1].id, new_status_id: statuses[0].id).first
      assert !w.author
      assert w.assignee

      # The always workflow is unchanged
      w = Workflow.where(role_id: role.id, type_id: type.id, old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                         assignee: false).first
      assert !w.author
      assert !w.assignee
    end
  end

  context "when switching tabs", :js do
    let!(:author_workflow) do
      create(:workflow, role_id: role.id, type_id: type.id,
                        old_status_id: statuses[1].id, new_status_id: statuses[2].id,
                        author: true, assignee: false)
    end
    let!(:assignee_workflow) do
      create(:workflow, role_id: role.id, type_id: type.id,
                        old_status_id: statuses[0].id, new_status_id: statuses[2].id,
                        author: false, assignee: true)
    end

    before do
      visit_workflow_edit(roles: [role])
    end

    it "shows the always tab by default" do
      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(0, 1), checked: true
      end
    end

    it "shows the author matrix when switching to the author tab" do
      click_link "User is author"

      within "#workflow_form_author" do
        expect(page).to have_field workflow_checkbox(1, 2), checked: true
        expect(page).to have_no_field workflow_checkbox(0, 1)
      end
    end

    it "shows the assignee matrix when switching to the assignee tab" do
      click_link "User is assignee"

      within "#workflow_form_assignee" do
        expect(page).to have_field workflow_checkbox(0, 2), checked: true
        expect(page).to have_no_field workflow_checkbox(0, 1)
      end
    end

    it "loses unsaved checkbox changes when switching tabs and ignoring" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      click_link "User is author"

      within_dialog "Save changes before continuing?" do
        click_button "Ignore changes"
      end

      click_link "Default transitions"

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: false
      end
    end

    it "saves changes and switches to the new tab when clicking 'Save changes and continue'" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      click_link "User is author"

      within_dialog "Save changes before continuing?" do
        click_button "Save changes and continue"
      end

      expect_flash(message: "Successful update.")

      expect(page).to have_css("#workflow_form_author")

      expect_transition(role, 1, 0, exist: true)
    end

    it "keeps unsaved changes and stays on the same tab when closing the dialog via 'X'" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      click_link "User is author"

      within_dialog "Save changes before continuing?" do
        find(".close-button").click
      end

      expect(page).to have_no_dialog("Save changes before continuing?")
      expect(page).to have_css("#workflow_form_always")

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: true
      end
    end

    it "shows a confirmation dialog when switching tabs after adding a status" do
      add_status_via_dialog(statuses[2])
      expect(page).to have_field workflow_checkbox(0, 2)

      click_link "User is author"

      expect(page).to have_dialog("Save changes before continuing?")
    end

    it "shows a confirmation dialog when switching tabs after removing a status" do
      remove_status_via_dialog(statuses[1])

      within_dialog "Remove statuses" do
        click_button "Remove"
      end

      expect(page).to have_no_field workflow_checkbox(0, 1)

      click_link "User is author"

      expect(page).to have_dialog("Save changes before continuing?")
    end
  end

  context "when switching roles", :js do
    let(:other_role) { create(:project_role) }
    let!(:other_workflow) do
      create(:workflow, role_id: other_role.id, type_id: type.id,
                        old_status_id: statuses[1].id, new_status_id: statuses[2].id,
                        author: false, assignee: false)
    end

    before do
      visit_workflow_edit(roles: [role])
    end

    it "shows the matrix for the first role" do
      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(0, 1)
        expect(page).to have_no_field workflow_checkbox(1, 2)
      end
    end

    it "loads the matrix for a different role after switching" do
      switch_role_via_panel(role, other_role)

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 2)
        expect(page).to have_no_field workflow_checkbox(0, 1)
      end
    end

    it "loses unsaved checkbox changes when switching roles and ignoring" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      switch_role_via_panel(role, other_role)

      within_dialog "Save changes before continuing?" do
        click_button "Ignore changes"
      end

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 2)
      end

      switch_role_via_panel(other_role, role)

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: false
      end
    end

    it "saves changes and switches to the new role when clicking 'Save changes and continue'" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      switch_role_via_panel(role, other_role)

      within_dialog "Save changes before continuing?" do
        click_button "Save changes and continue"
      end

      expect_flash(message: "Successful update.")

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 2)
      end

      expect_transition(role, 1, 0, exist: true)
    end

    it "keeps unsaved changes and stays on the same role when closing the dialog via 'X'" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      switch_role_via_panel(role, other_role)

      within_dialog "Save changes before continuing?" do
        find(".close-button").click
      end

      expect(page).to have_no_dialog("Save changes before continuing?")

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(0, 1)
        expect(page).to have_field workflow_checkbox(1, 0), checked: true
      end
    end

    it "shows a confirmation dialog when changing roles after adding a status" do
      add_status_via_dialog(statuses[2])
      expect(page).to have_field workflow_checkbox(0, 2)

      switch_role_via_panel(role, other_role)

      expect(page).to have_dialog("Save changes before continuing?")
    end

    it "shows a confirmation dialog when changing roles after removing a status" do
      remove_status_via_dialog(statuses[1])

      within_dialog "Remove statuses" do
        click_button "Remove"
      end

      expect(page).to have_no_field workflow_checkbox(0, 1)

      switch_role_via_panel(role, other_role)

      expect(page).to have_dialog("Save changes before continuing?")
    end
  end

  context "when reloading the page with unsaved changes", :js do
    before do
      visit_workflow_edit(roles: [role])
    end

    it "shows a browser confirmation when reloading with unsaved checkbox changes" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      dismiss_confirm do
        page.driver.refresh
      end

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: true
      end
    end

    it "reloads and discards changes when accepting the browser confirmation" do
      within "#workflow_form_always" do
        check workflow_checkbox(1, 0)
      end

      accept_confirm do
        page.driver.refresh
      end

      within "#workflow_form_always" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: false
      end
    end

    it "does not show a confirmation when reloading with no unsaved changes" do
      page.driver.refresh

      expect(page).to have_css("#workflow_form_always")
    end
  end

  context "with status dialog", :js do
    before do
      visit_workflow_edit(roles: [role])
    end

    it "shows only role-specific statuses in the matrix by default" do
      other_role = create(:project_role)
      create(:workflow, role_id: other_role.id, type_id: type.id,
                        old_status_id: statuses[0].id, new_status_id: statuses[2].id)

      visit_workflow_edit(roles: [role])

      expect(page).to have_field workflow_checkbox(0, 1)
      expect(page).to have_no_field workflow_checkbox(2, 0)
      expect(page).to have_no_field workflow_checkbox(0, 2)
    end

    it "pre selects the current role statuses in the dialog" do
      within "#workflow-table" do
        click_link "Status"
      end

      expect(page).to have_dialog("Statuses")
      within_dialog "Statuses" do
        expect(page).to have_css(".ng-value-label", text: statuses[0].name)
        expect(page).to have_css(".ng-value-label", text: statuses[1].name)
        expect(page).to have_no_css(".ng-value-label", text: statuses[2].name)
      end
    end

    it "adds a new status via the dialog and shows it in the workflow table" do
      expect(page).to have_no_field workflow_checkbox(2, 0)
      expect(page).to have_no_field workflow_checkbox(0, 2)

      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(2, 0)
      expect(page).to have_field workflow_checkbox(0, 2)
    end

    it "checks all new checkboxes when adding a new status" do
      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(2, 0), checked: true
      expect(page).to have_field workflow_checkbox(0, 2), checked: true
      expect(page).to have_field workflow_checkbox(2, 1), checked: true
      expect(page).to have_field workflow_checkbox(1, 2), checked: true
      expect(page).to have_field workflow_checkbox(2, 2), checked: true
    end

    it "removes the status after confirming the danger dialog" do
      expect(page).to have_field workflow_checkbox(0, 1)

      remove_status_via_dialog(statuses[1])

      expect(page).to have_dialog("Remove statuses")

      within_dialog "Remove statuses" do
        expect(page).to have_text("Remove 1 status?")

        click_button "Remove"
      end

      expect(page).to have_no_field workflow_checkbox(0, 1)
    end

    it "cancels the status dialog without changing the matrix" do
      expect(page).to have_no_field workflow_checkbox(2, 0)

      within "#workflow-table" do
        click_link "Status"
      end

      within_dialog "Statuses" do
        find(".ng-arrow-wrapper").click
        find(".ng-option", text: statuses[2].name).click
        click_button "Cancel"
      end

      expect(page).to have_no_dialog("Statuses")

      expect(page).to have_no_field workflow_checkbox(2, 0)
    end

    it "cancels the removal danger dialog and keeps the status in the matrix" do
      expect(page).to have_field workflow_checkbox(0, 1)

      remove_status_via_dialog(statuses[1])

      within_dialog "Remove statuses" do
        click_button "Cancel"
      end

      expect(page).to have_no_dialog("Remove statuses")

      expect(page).to have_field workflow_checkbox(0, 1)
    end

    it "saves after adding a status via the dialog and persists it in the database" do
      expect(page).to have_no_field workflow_checkbox(2, 0)

      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(2, 0)

      click_button "Save"

      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 2, exist: true)

      expect(page).to have_field workflow_checkbox(0, 2)

      page.driver.refresh

      expect(page).to have_field workflow_checkbox(2, 0)
    end

    it "reverts applied statuses when navigating away without saving" do
      expect(page).to have_no_field workflow_checkbox(2, 0)

      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(2, 0)

      visit_workflow_edit(roles: [role])

      expect(page).to have_no_field workflow_checkbox(2, 0)
    end

    it "preserves existing checkbox changes after adding a new status via the dialog" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: true
      uncheck workflow_checkbox(0, 1)
      expect(page).to have_field workflow_checkbox(0, 1), checked: false

      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(page).to have_field workflow_checkbox(2, 0)
    end

    it "preserves existing checkbox changes after removing an unrelated status" do
      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(0, 1), checked: true
      uncheck workflow_checkbox(0, 1)
      expect(page).to have_field workflow_checkbox(0, 1), checked: false

      remove_status_via_dialog(statuses[2])

      within_dialog "Remove statuses" do
        click_button "Remove"
      end

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
    end

    it "removes an unused status on save" do
      add_status_via_dialog(statuses[2])

      expect(page).to have_field workflow_checkbox(2, 0)

      uncheck workflow_checkbox(2, 0)
      uncheck workflow_checkbox(0, 2)
      uncheck workflow_checkbox(2, 1)
      uncheck workflow_checkbox(1, 2)
      uncheck workflow_checkbox(2, 2)

      click_button "Save"

      expect_flash(message: "Successful update.")

      visit_workflow_edit(roles: [role])

      expect(page).to have_no_field workflow_checkbox(2, 0)
      expect(page).to have_no_field workflow_checkbox(0, 2)
      expect(page).to have_no_field workflow_checkbox(2, 1)
      expect(page).to have_no_field workflow_checkbox(1, 2)
      expect(page).to have_no_field workflow_checkbox(2, 2)
    end

    it "shows a blankslate when no statuses are configured" do
      uncheck workflow_checkbox(0, 1)

      click_button "Save"

      expect_flash(message: "Successful update.")

      expect(page).to have_text("No status transitions configured")
      expect(page).to have_text("Add statuses to start configuring workflows for this role")
    end
  end

  context "with copy dialog" do
    it "allows navigating to any Copy page", :js do
      within ".PageHeader-actions" do
        click_on "Copy"
      end

      expect(page).to have_dialog "Copy workflow"
    end

    context "with unsaved checkbox" do
      it "loses unsaved checkbox changes when clicking on copy and ignoring" do
        within "#workflow_form_always" do
          check workflow_checkbox(1, 0)
        end

        click_link "Copy"

        within_dialog "Save changes before continuing?" do
          click_button "Ignore changes"
        end

        within "#workflow_form_always" do
          expect(page).to have_field workflow_checkbox(1, 0), checked: false
        end
        expect(page).to have_dialog "Copy workflow"
      end

      it "saves changes and switches to the new role when clicking 'Save changes and continue'" do
        within "#workflow_form_always" do
          check workflow_checkbox(1, 0)
        end

        click_link "Copy"

        within_dialog "Save changes before continuing?" do
          click_button "Save changes and continue"
        end

        expect_flash(message: "Successful update.")

        expect_transition(role, 1, 0, exist: true)

        expect(page).to have_dialog "Copy workflow"
      end

      it "keeps unsaved changes and stays on the same role when closing the dialog via 'X'" do
        within "#workflow_form_always" do
          check workflow_checkbox(1, 0)
        end

        click_link "Copy"

        within_dialog "Save changes before continuing?" do
          find(".close-button").click
        end

        expect(page).to have_no_dialog("Save changes before continuing?")

        within "#workflow_form_always" do
          expect(page).to have_field workflow_checkbox(1, 0), checked: true
        end

        expect(page).to have_no_dialog "Copy workflow"
      end
    end

    context "with unsaved new status" do
      it "shows a confirmation dialog when copying after adding a status" do
        add_status_via_dialog(statuses[2])
        expect(page).to have_field workflow_checkbox(0, 2)

        click_link "Copy"

        expect(page).to have_dialog("Save changes before continuing?")
      end

      it "reverts the added status on changes ignored" do
        add_status_via_dialog(statuses[2])
        expect(page).to have_field workflow_checkbox(0, 2)

        click_link "Copy"

        within_dialog "Save changes before continuing?" do
          click_button "Ignore changes"
        end

        expect(page).to have_no_field workflow_checkbox(0, 2)
      end

      it "reverts the removed status on changes ignored" do
        remove_status_via_dialog(statuses[1])

        within_dialog "Remove statuses" do
          expect(page).to have_text("Remove 1 status?")

          click_button "Remove"
        end

        expect(page).to have_no_field workflow_checkbox(0, 1)

        click_link "Copy"

        within_dialog "Save changes before continuing?" do
          click_button "Ignore changes"
        end

        expect(page).to have_field workflow_checkbox(0, 1)
      end
    end
  end
end
