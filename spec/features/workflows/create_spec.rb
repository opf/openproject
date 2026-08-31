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

RSpec.describe "Creating a named workflow", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers
  include Workflows::EditHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status, name: "New") }
  shared_let(:status_b) { create(:status, name: "In progress") }

  shared_let(:existing) { create(:named_workflow, name: "Standard flow", description: "The agreed one") }

  before_all do
    create(:workflow, workflow: existing, role:, old_status: status_a, new_status: status_b)
  end

  before { login_as admin }

  def add_first_status(status)
    within("#workflow-table") { first(:link, "Status").click }
    within_dialog "Statuses" do
      find(".ng-arrow-wrapper").click
      find(".ng-option", text: status.name).click
      click_button "Apply"
    end
  end

  def open_create_dialog
    visit workflows_path
    click_on "Workflow"
    expect(page).to have_css("#workflow-dialog")
  end

  it "creates a workflow and lands on its own page" do
    open_create_dialog

    fill_in "Workflow name", with: "Release flow"
    fill_in "Description", with: "How releases move"
    click_on "Create"

    expect(page).to have_current_path(%r{/workflows/\d+/edit})
    expect(page).to have_text("No type or variant uses this workflow yet.")
    expect(page).to have_css(".PageHeader-title", text: "Release flow")

    expect(Workflow.find_by(name: "Release flow").description).to eq("How releases move")
  end

  it "copies the transitions of the workflow it was told to start from" do
    open_create_dialog

    fill_in "Workflow name", with: "Copied flow"

    select_autocomplete page.find("[data-test-selector='workflow-copy-from']"),
                        query: "Standard",
                        results_selector: "body"

    click_on "Create"

    expect(page).to have_current_path(%r{/workflows/\d+/edit})

    created = Workflow.find_by(name: "Copied flow")
    expect(created.status_transitions.pluck(:old_status_id, :new_status_id))
      .to contain_exactly([status_a.id, status_b.id])
  end

  it "refuses a name another workflow already has" do
    open_create_dialog

    fill_in "Workflow name", with: "Standard flow"
    click_on "Create"

    expect(page).to have_css("#workflow-dialog")
    expect(page).to have_text("Name has already been taken")
  end

  it "edits status transitions on the new workflow's own page" do
    open_create_dialog

    fill_in "Workflow name", with: "Release flow"
    click_on "Create"
    expect(page).to have_text("No type or variant uses this workflow yet.")

    add_first_status(status_a)
    add_status_via_dialog(status_b)

    check "status_#{status_a.id}_#{status_b.id}"
    click_on "Save"

    expect(page).to have_text(I18n.t(:notice_successful_update))

    created = Workflow.find_by(name: "Release flow")
    expect(created.status_transitions.pluck(:old_status_id, :new_status_id))
      .to include([status_a.id, status_b.id])
  end

  it "offers each row action once, and only one of them opens the dialog" do
    visit workflows_path

    find(:button, accessible_name: "Actions for Standard flow").click

    expect(page).to have_link("Edit transitions", count: 1)
    expect(page).to have_link("Edit name and description", count: 1)

    click_on "Edit name and description"

    expect(page).to have_css("#workflow-dialog")
    expect(page).to have_field("Workflow name", with: "Standard flow")
  end

  it "offers Copy from only while creating, never when editing" do
    open_create_dialog
    expect(page).to have_css("[data-test-selector='workflow-copy-from']")
    click_on "Cancel"

    visit edit_workflow_path(existing)
    click_on "Edit"

    expect(page).to have_css("#workflow-dialog")
    expect(page).to have_field("Workflow name", with: "Standard flow")
    expect(page).to have_no_css("[data-test-selector='workflow-copy-from']")
  end

  it "lists the new workflow on the index" do
    open_create_dialog

    fill_in "Workflow name", with: "Release flow"
    click_on "Create"
    expect(page).to have_text("No type or variant uses this workflow yet.")

    visit workflows_path

    expect(page).to have_text("Release flow")
    expect(page).to have_text("Standard flow")
  end

  describe "from a project-owned variant's workflow tab" do
    shared_let(:type) { create(:type, name: "Bug") }
    shared_let(:project) { create(:project, name: "Bookshop", types: [type]) }
    shared_let(:variant) do
      create(:project_owned_type_variant, type:, project:, variant_name: "Internal")
    end
    shared_let(:project_admin) do
      create(:user, member_with_permissions: { project => %i[manage_project_variants] })
    end

    let(:tab_path) do
      edit_type_workflow_path(in_project_id: project, type_id: type.id, variant_id: variant.id)
    end

    before { login_as project_admin }

    it "creates a workflow the project owns and assigns it to the variant" do
      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Create new workflow" }

      within_dialog "Create workflow" do
        fill_in "Workflow name", with: "Internal flow"
        fill_in "Description", with: "How our tickets move"
        click_on "Create"
      end

      expect(page).to have_current_path(tab_path)

      created = variant.reload.workflow
      expect(created).to have_attributes(name: "Internal flow", description: "How our tickets move")
      expect(created.project).to eq(project)
    end

    it "may take a name administration already holds" do
      expect(Workflow.global.where(name: "Standard flow")).to be_present

      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Create new workflow" }

      within_dialog "Create workflow" do
        fill_in "Workflow name", with: "Standard flow"
        click_on "Create"
      end

      expect(page).to have_current_path(tab_path)
      expect(variant.reload.workflow.project).to eq(project)
      expect(Workflow.owned_by(project).where(name: "Standard flow")).to be_present
    end

    it "refuses a name the project already uses" do
      create(:project_owned_workflow, project:, name: "Internal flow")

      visit tab_path

      within_test_selector("workflow-reuse-mode") { click_on "Create new workflow" }

      within_dialog "Create workflow" do
        fill_in "Workflow name", with: "Internal flow"
        click_on "Create"

        expect(page).to have_text("Name has already been taken")
      end
    end
  end
end
