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

RSpec.describe "Workflow edit with multiple roles", :js do
  include Toasts::Expectations
  include Workflows::EditHelpers

  let(:role)  { create(:project_role) }
  let(:role2) { create(:project_role) }
  let(:type)  { create(:type) }
  let(:admin) { create(:admin) }
  let(:statuses) { (1..3).map { create(:status) } }

  # workflow for 0 -> 1 for 'role'
  let!(:role_workflow) do
    create(:workflow, role_id: role.id, type_id: type.id,
                      old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                      author: false, assignee: false)
  end

  current_user { admin }

  context "when displaying checkboxes" do
    context "when all selected roles have a transition" do
      let!(:role2_workflow) do
        create(:workflow, role_id: role2.id, type_id: type.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
      end

      before { visit_workflow_edit(roles: [role, role2]) }

      it "shows the checkbox as checked" do
        expect(page).to have_field workflow_checkbox(0, 1), checked: true
        expect(indeterminate?(workflow_checkbox(0, 1))).to be false
      end
    end

    context "when no selected roles have a transition" do
      before { visit_workflow_edit(roles: [role, role2]) }

      it "shows the checkbox as unchecked" do
        expect(page).to have_field workflow_checkbox(1, 0), checked: false
        expect(indeterminate?(workflow_checkbox(1, 0))).to be false
      end
    end

    context "when only some selected roles have a transition" do
      before { visit_workflow_edit(roles: [role, role2]) }

      it "shows the checkbox as indeterminate" do
        expect(page).to have_field workflow_checkbox(0, 1), checked: false
        expect(indeterminate?(workflow_checkbox(0, 1))).to be true
      end

      it "the checkbox is visible as indeterminate" do
        expect(page).to have_field workflow_checkbox(0, 1), checked: false

        expect(indeterminate?(workflow_checkbox(0, 1))).to be true
        expect(indeterminate_visible?(workflow_checkbox(0, 1))).to be true
      end
    end

    context "when roles have different statuses in their workflows" do
      let!(:role2_workflow) do
        create(:workflow, role_id: role2.id, type_id: type.id,
                          old_status_id: statuses[1].id, new_status_id: statuses[2].id,
                          author: false, assignee: false)
      end

      before { visit_workflow_edit(roles: [role, role2]) }

      it "shows the union of statuses from all selected roles" do
        expect(page).to have_field workflow_checkbox(0, 2)
        expect(page).to have_field workflow_checkbox(1, 2)
      end

      it "pre-selects the union of statuses from all selected roles in the status dialog" do
        within "#workflow-table" do
          click_link "Status"
        end

        expect(page).to have_dialog("Statuses")
        within_dialog "Statuses" do
          expect(page).to have_css(".ng-value-label", text: statuses[0].name)
          expect(page).to have_css(".ng-value-label", text: statuses[1].name)
          expect(page).to have_css(".ng-value-label", text: statuses[2].name)
        end
      end
    end

    context "with a single role selected" do
      before { visit_workflow_edit(roles: [role]) }

      it "does not show indeterminate checkboxes" do
        expect(page).to have_field workflow_checkbox(0, 1), checked: true
        expect(indeterminate?(workflow_checkbox(0, 1))).to be false
      end
    end
  end

  context "when saving" do
    before { visit_workflow_edit(roles: [role, role2]) }

    it "adds the transition for all roles when checking an unchecked checkbox" do
      expect_transition(role, 1, 0, exist: false)
      expect_transition(role2, 1, 0, exist: false)

      check workflow_checkbox(1, 0)
      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 1, 0, exist: true)
      expect_transition(role2, 1, 0, exist: true)
    end

    it "preserves state for each role when saving an untouched indeterminate checkbox" do
      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: false)

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: false)

      expect(indeterminate?(workflow_checkbox(0, 1))).to be true
    end

    it "adds the transition for all roles when checking an indeterminate checkbox" do
      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: false)

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      check workflow_checkbox(0, 1)
      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: true)

      expect(indeterminate?(workflow_checkbox(0, 1))).to be false
    end

    it "removes the transition from all roles when unchecking an indeterminate checkbox" do
      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: false)

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      check workflow_checkbox(0, 1)
      uncheck workflow_checkbox(0, 1)
      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: false)
      expect_transition(role2, 0, 1, exist: false)

      expect(indeterminate?(workflow_checkbox(0, 1))).to be false
    end

    context "when all roles have the transition" do
      let!(:role2_workflow) do
        create(:workflow, role_id: role2.id, type_id: type.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                          author: false, assignee: false)
      end

      before { visit_workflow_edit(roles: [role, role2]) }

      it "removes the transition from all roles when unchecking a fully checked checkbox" do
        expect_transition(role, 0, 1, exist: true)
        expect_transition(role2, 0, 1, exist: true)

        uncheck workflow_checkbox(0, 1)
        click_button "Save"
        expect_flash(message: "Successful update.")

        expect_transition(role, 0, 1, exist: false)
        expect_transition(role2, 0, 1, exist: false)
      end
    end

    context "with multiple indeterminate checkboxes" do
      let!(:role_workflow2) do
        create(:workflow, role_id: role.id, type_id: type.id,
                          old_status_id: statuses[0].id, new_status_id: statuses[2].id,
                          author: false, assignee: false)
      end

      before { visit_workflow_edit(roles: [role, role2]) }

      it "handles touched and untouched indeterminate checkboxes independently" do
        # Both 0 -> 1 and 0 -> 2 are indeterminate
        expect_transition(role, 0, 1, exist: true)
        expect_transition(role2, 0, 1, exist: false)
        expect_transition(role, 0, 2, exist: true)
        expect_transition(role2, 0, 2, exist: false)

        check workflow_checkbox(0, 1) # explicitly check for all roles

        click_button "Save"
        expect_flash(message: "Successful update.")

        # role2 now has this workflow
        expect_transition(role2, 0, 1, exist: true)

        # 0 -> 2 stays indeterminate
        expect_transition(role, 0, 2, exist: true)
        expect_transition(role2, 0, 2, exist: false)
      end
    end

    it "marks the form dirty when interacting with an indeterminate checkbox" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      check workflow_checkbox(0, 1)

      click_link "User is author"
      expect(page).to have_dialog("Save changes before continuing?")
    end

    it "succeeds when saving with no changes to indeterminate checkboxes" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      click_button "Save"
      expect_flash(message: "Successful update.")
    end

    it "bulk-checks an indeterminate cell when toggling its column" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      toggle_select_all_in_column(1)

      expect(page).to have_field workflow_checkbox(0, 1), checked: true
      expect(indeterminate?(workflow_checkbox(0, 1))).to be false

      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: true)
    end

    it "bulk-checks an indeterminate cell when toggling its row" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      toggle_select_all_in_row(0)

      expect(page).to have_field workflow_checkbox(0, 1), checked: true
      expect(indeterminate?(workflow_checkbox(0, 1))).to be false

      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: true)
      expect_transition(role2, 0, 1, exist: true)
    end

    it "bulk-unchecks an indeterminate cell when toggling its column twice" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      toggle_select_all_in_column(1) # check all
      toggle_select_all_in_column(1) # uncheck all

      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be false

      click_button "Save"
      expect_flash(message: "Successful update.")

      expect_transition(role, 0, 1, exist: false)
      expect_transition(role2, 0, 1, exist: false)
    end

    it "marks the form dirty when bulk-toggling a column" do
      expect(page).to have_field workflow_checkbox(0, 1), checked: false
      expect(indeterminate?(workflow_checkbox(0, 1))).to be true

      toggle_select_all_in_column(1)

      click_link "User is author"
      expect(page).to have_dialog("Save changes before continuing?")
    end
  end

  context "when deselecting all roles in the select panel" do
    before { visit_workflow_edit(roles: [role, role2]) }

    it "falls back to the first eligible role instead of leaving the page stuck" do
      click_button "2 roles selected"
      find("[data-item-id='#{role.id}']").click
      find("[data-item-id='#{role2.id}']").click
      within("select-panel") { click_button "Apply" }

      expect(page).to have_no_text("2 roles selected")
      expect(page).to have_button(role.name)
    end
  end

  context "when modifying statuses" do
    before { visit_workflow_edit(roles: [role, role2]) }

    it "preserves all selected roles after adding a status" do
      add_status_via_dialog(statuses[2])

      expect(page).to have_text("2 roles selected")
    end

    it "preserves all selected roles after removing a status via the danger dialog" do
      remove_status_via_dialog(statuses[1])

      within_dialog("Remove statuses") { click_button "Remove" }

      expect(page).to have_text("2 roles selected")
    end

    it "checks all new status checkboxes as fully checked, not indeterminate, when adding a status" do
      add_status_via_dialog(statuses[2])

      [workflow_checkbox(2, 0), workflow_checkbox(0, 2), workflow_checkbox(2, 1),
       workflow_checkbox(1, 2), workflow_checkbox(2, 2)].each do |cb|
        expect(page).to have_field cb, checked: true
        expect(indeterminate?(cb)).to be false
      end
    end

    context "when no statuses are configured" do
      let(:empty_role1) { create(:project_role) }
      let(:empty_role2) { create(:project_role) }

      before { visit_workflow_edit(roles: [empty_role1, empty_role2]) }

      it "shows a blankslate" do
        expect(page).to have_text("No status transitions configured")
      end

      it "preserves all selected roles when adding statuses from the blankslate" do
        within "#workflow-table" do
          all(:link, "Status").last.click
        end
        within_dialog "Statuses" do
          find(".ng-arrow-wrapper").click
          find(".ng-option", text: statuses[0].name).click
          click_button "Apply"
        end

        expect(page).to have_text("2 roles selected")
      end
    end
  end
end
