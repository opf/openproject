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

  def open_create_dialog(start: "scratch", &)
    visit workflows_path
    wait_for_turbo_stream { click_on "Workflow" }
    run_workflow_start_dialog(start:, &)

    expect(page).to have_field("Workflow name")
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
    open_create_dialog(start: "copy") do
      select_autocomplete(find_test_selector("workflow-copy-source"),
                          query: "Standard",
                          results_selector: "#workflow-dialog")
    end

    fill_in "Workflow name", with: "Copied flow"
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

  it "settles the source before naming, and never asks for it twice" do
    visit workflows_path
    wait_for_turbo_stream { click_on "Workflow" }

    within_dialog I18n.t("workflows.start.title") do
      expect(page).to have_test_selector("workflow-copy-source")
      choose_workflow_start("scratch")
      click_on I18n.t(:button_continue)
    end

    expect(page).to have_field("Workflow name")
    expect(page).to have_no_css("[data-test-selector='workflow-copy-from']")
  end

  it "asks for no source when editing a workflow that already exists" do
    visit edit_workflow_path(existing)
    find_test_selector("workflow-actions").click
    click_on "Edit"

    expect(page).to have_css("#workflow-dialog")
    expect(page).to have_field("Workflow name", with: "Standard flow")
    expect(page).to have_no_css("[data-test-selector='workflow-copy-from']")
  end

  it "deletes the workflow from its own page" do
    spare = create(:named_workflow, name: "Spare flow")

    visit edit_workflow_path(spare)
    find_test_selector("workflow-actions").click

    accept_confirm { find_test_selector("workflow-delete-action").click }

    expect(page).to have_current_path(workflows_path)
    expect(page).to have_text(I18n.t(:notice_successful_delete))
    expect(Workflow).not_to exist(spare.id)
  end

  it "refuses to delete a workflow a type still uses" do
    in_use = create(:type, name: "Task").default_variant.workflow

    visit edit_workflow_path(in_use)
    find_test_selector("workflow-actions").click

    accept_confirm { find_test_selector("workflow-delete-action").click }

    expect(page).to have_current_path(workflows_path)
    expect(Workflow).to exist(in_use.id)
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
end
