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

RSpec.describe "Type creation wizard workflows step", :js, with_flag: { type_variants: true } do
  include Toasts::Expectations
  include Workflows::EditHelpers

  let(:type) { create(:type) }
  let(:role) { create(:project_role) }
  let(:role2) { create(:project_role) }
  let(:admin) { create(:admin) }
  let(:statuses) { (1..3).map { create(:status) } }
  let!(:workflow) do
    create(:workflow, role_id: role.id, type_id: type.id,
                      old_status_id: statuses[0].id, new_status_id: statuses[1].id,
                      author: false, assignee: false)
  end

  current_user { admin }

  # Parallels Workflows::EditHelpers#visit_workflow_edit, but for the wizard
  def visit_workflow_wizard(roles: [], tab: nil)
    params = { step: :workflows }
    params[:role_ids] = roles.map(&:id) if roles.any?
    params[:tab] = tab if tab
    visit type_creation_wizard_path(type, **params)
  end

  def workflows_for(type, role)
    Workflow.where(type_variant_id: type.default_variant.id, role_id: role.id)
  end

  it "persists the matrix and advances when clicking 'Continue'" do
    visit_workflow_wizard(roles: [role])

    expect(page).to have_field workflow_checkbox(1, 0), checked: false
    expect(workflows_for(type, role).count).to be 1

    check workflow_checkbox(1, 0)

    expect(page).to have_no_button "Save"
    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(type_creation_wizard_path(type, step: :projects))
    expect(workflows_for(type, role).count).to be 2
  end

  context "when switching tabs" do
    let!(:author_workflow) do
      create(:workflow, role_id: role.id, type_id: type.id,
                        old_status_id: statuses[1].id, new_status_id: statuses[2].id,
                        author: true, assignee: false)
    end

    before { visit_workflow_wizard(roles: [role]) }

    it "shows the author matrix when switching to the author tab" do
      expect(page).to have_no_css "#workflow_form_author"

      switch_transition_tab "User is author"

      within "#workflow_form_author" do
        expect(page).to have_field workflow_checkbox(1, 2), checked: true
        expect(page).to have_no_field workflow_checkbox(0, 1)
      end
    end

    # The wizard form advances a step, so saving from the dialog has to go through the
    # matrix's own endpoint instead — otherwise the change is dropped or the user is
    # thrown off the step (see MatrixEditorComponent).
    it "stores pending changes and stays on the step when confirming the save" do
      check workflow_checkbox(1, 0)

      switch_transition_tab "User is author"

      within_dialog "Save changes before continuing?" do
        click_button "Save changes and continue"
      end

      expect(page).to have_css "#workflow_form_author"
      expect(page).to have_current_path(/step=workflows/)

      expect_transition(role, 1, 0, exist: true)
    end

    it "keeps the step and discards the change when ignoring" do
      check workflow_checkbox(1, 0)

      switch_transition_tab "User is author"

      within_dialog "Save changes before continuing?" do
        click_button "Ignore changes"
      end

      expect(page).to have_css "#workflow_form_author"
      expect_transition(role, 1, 0, exist: false)
    end
  end

  context "when switching roles" do
    before { visit_workflow_wizard(roles: [role, role2]) }

    it "shows the matrix for the selected role" do
      expect(page).to have_text("2 roles selected")
      expect(page).to have_no_button(role.name)

      click_button "2 roles selected"
      find("[data-item-id='#{role2.id}']").click
      within("select-panel") { click_button "Apply" }

      expect(page).to have_no_text("2 roles selected")
      expect(page).to have_button(role.name)
    end
  end

  describe "when the workflow is linked from a source" do
    let(:source_type) { create(:type) }
    let!(:source_workflow) do
      create(:workflow, role_id: role.id,
                        type_id: source_type.id,
                        old_status_id: statuses[0].id,
                        new_status_id: statuses[1].id,
                        author: false,
                        assignee: false)
    end

    before do
      link_configuration(type, source: source_type, aspect: TypeVariant::WORKFLOWS)
      visit_workflow_wizard(roles: [role])
    end

    it "shows the source's transitions read-only without editing actions" do
      expect(page).to have_field(workflow_checkbox(0, 1), checked: true, disabled: true)
      expect(page).to have_field(workflow_checkbox(1, 0), disabled: true)
      expect(page).to have_no_button "Save"

      within "#workflow-table" do
        expect(page).to have_no_link "Status"
        expect(page).to have_no_link "Copy"
      end
    end
  end

  describe "reuse mode boxes" do
    context "when the workflow configuration is independent" do
      before { visit_workflow_wizard(roles: [role]) }

      it "shows the manual box offering to inherit from another type, or to copy from one" do
        expect(page).to have_text("Manual configuration")
        expect(page).to have_link("Inherit from another type")
        expect(page).to have_link("Copy from another type")
      end
    end

    context "when the workflow configuration is linked to a source" do
      let(:source_type) { create(:type, name: "Feature") }

      before do
        link_configuration(type, source: source_type, aspect: TypeVariant::WORKFLOWS)
        visit_workflow_wizard(roles: [role])
      end

      it "shows the inherited box naming the source with change and switch actions" do
        expect(page).to have_text("Inherited configuration")
        expect(page).to have_link("Change source type")
        expect(page).to have_link("Configure manually")
      end
    end
  end
end
