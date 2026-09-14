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

RSpec.describe "Managing text transform actions", :js, with_flag: { ai_text_transform_actions: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type_bug) { create(:type, name: "Bug") }
  shared_let(:type_task) { create(:type, name: "Task") }

  current_user { admin }

  def toggle_label(action)
    I18n.t("admin.text_transform_actions.row_component.label_toggle", label: action.label)
  end

  def row_selector(action)
    "text-transform-action-row-#{action.id}"
  end

  def within_row_menu(action, &)
    within_test_selector(row_selector(action)) do
      find_test_selector("text-transform-action-menu").click_link_or_button
      within("anchored-position", &)
    end
  end

  def expect_toggle_state(action, pressed:)
    expect(page).to have_button(accessible_name: toggle_label(action), aria: { pressed: })
  end

  def expect_scope(action, text)
    within_test_selector(row_selector(action)) do
      expect(page).to have_test_selector("text-transform-action-scope", text:)
    end
  end

  it "shows the menu entry and a blank slate" do
    visit admin_text_transform_actions_path

    within("#menu-sidebar") do
      expect(page).to have_link("Text transform actions", href: %r{/admin/text_transform_actions\z})
    end

    expect(page).to have_css(".PageHeader-title", text: "Text transform actions")
    expect(page).to have_text("No text transform actions configured yet")
  end

  it "creates an action scoped to specific work package types" do
    visit admin_text_transform_actions_path

    within(".SubHeader") { click_on "Action" }
    expect(page).to have_current_path(new_admin_text_transform_action_path)

    expect(page).to have_no_test_selector("text-transform-action-select-types")
    expect(page).to have_no_field("Insert work package type template")

    fill_in "Label", with: "Translate to English"
    fill_in "Prompt", with: "Translate the text into English."
    select "Specific work package types", from: "Scope"
    expect(page).to have_test_selector("text-transform-action-select-types")
    expect(page).to have_field("Insert work package type template")

    wait_for_turbo_stream { click_on "Create" }
    expect(page).to have_text("Work package types can't be blank")

    find_test_selector("text-transform-action-select-types").click
    within_test_selector("text-transform-action-types-panel") do
      find("[role='option']", text: "Bug").click
    end
    find("body").send_keys(:escape)
    expect(find_test_selector("text-transform-action-select-types")).to have_text("Bug")

    check "Insert work package type template"
    wait_for_turbo(wait: 10) { click_on "Create" }

    expect(page).to have_current_path(admin_text_transform_actions_path)
    expect_flash(message: "Successful creation.")

    action = AI::TextTransformAction.find_by!(label: "Translate to English")
    expect(action.types).to eq([type_bug])
    expect(action).to be_injects_type_template
    expect_scope(action, "1 work package type")
  end

  it "edits an action" do
    action = create(:ai_text_transform_action, label: "Fix grammar")

    visit admin_text_transform_actions_path
    within_test_selector(row_selector(action)) { click_on "Fix grammar" }

    expect(page).to have_current_path(edit_admin_text_transform_action_path(action))
    expect(page).to have_css(".PageHeader-title", text: "Fix grammar")

    fill_in "Label", with: "Fix spelling"
    select "All work package types", from: "Scope"
    wait_for_turbo(wait: 10) { click_on "Save" }

    expect(page).to have_current_path(admin_text_transform_actions_path)
    expect_flash(message: "Successful update.")

    action.reload
    expect(action.label).to eq("Fix spelling")
    expect(action).to be_all_work_package_types
    expect_scope(action, "All work package types")
  end

  it "toggles actions individually and in bulk", with_settings: { ai_text_transform_actions_enabled: true } do
    first_action = create(:ai_text_transform_action, active: true)
    second_action = create(:ai_text_transform_action, active: true)

    visit admin_text_transform_actions_path

    expect_toggle_state(first_action, pressed: true)
    find(:button, accessible_name: toggle_label(first_action)).click
    expect_toggle_state(first_action, pressed: false)
    wait_for_network_idle
    expect(first_action.reload).not_to be_active

    wait_for_turbo_stream { click_on "Disable all" }
    expect_toggle_state(first_action, pressed: false)
    expect_toggle_state(second_action, pressed: false)
    expect(AI::TextTransformAction.active).to be_empty

    wait_for_turbo_stream { click_on "Enable all" }
    expect_toggle_state(first_action, pressed: true)
    expect_toggle_state(second_action, pressed: true)
    expect(AI::TextTransformAction.active.count).to eq(2)
  end

  it "reorders actions via the action menu" do
    first_action = create(:ai_text_transform_action, label: "First")
    second_action = create(:ai_text_transform_action, label: "Second")

    visit admin_text_transform_actions_path

    wait_for_turbo_stream do
      within_row_menu(first_action) { click_on "Move to bottom" }
    end

    expect(page).to have_css("[data-test-selector^='text-transform-action-row-']:first-child", text: "Second")
    expect(AI::TextTransformAction.ordered.ids).to eq([second_action.id, first_action.id])
  end

  it "deletes an action via the danger dialog" do
    action = create(:ai_text_transform_action, label: "Make concise")

    visit admin_text_transform_actions_path

    within_row_menu(action) { click_on "Delete" }

    page.within_modal("Delete text transform action") do
      expect(page).to have_text('Are you sure you want to delete the action "Make concise"?')
      click_on "Delete"
    end

    expect(page).to have_current_path(admin_text_transform_actions_path, wait: 10)
    expect_flash(message: "Successful deletion.")
    expect(AI::TextTransformAction.where(id: action.id)).not_to exist
    expect(page).to have_text("No text transform actions configured yet")
  end

  it "toggles the global setting, releasing the list from its disabled state" do
    action = create(:ai_text_transform_action, active: true)

    visit admin_text_transform_actions_path

    expect(page).to have_button(accessible_name: "Enable text transform actions", aria: { pressed: false })
    expect(page).to have_test_selector("text-transform-actions-disabled-banner")
    expect(page).to have_button(accessible_name: toggle_label(action), disabled: true)

    wait_for_turbo_stream { find(:button, accessible_name: "Enable text transform actions").click }

    expect(page).to have_button(accessible_name: "Enable text transform actions", aria: { pressed: true })
    expect(page).to have_no_test_selector("text-transform-actions-disabled-banner")
    expect(page).to have_button(accessible_name: toggle_label(action), aria: { pressed: true })
    expect(Setting.find_by(name: "ai_text_transform_actions_enabled")&.value).to be(true)
  end

  it "hides the menu entry and the page when the feature flag is inactive",
     with_flag: { ai_text_transform_actions: false } do
    visit mcp_configurations_path

    within("#menu-sidebar") do
      expect(page).to have_link("Model Context Protocol (MCP)")
      expect(page).to have_no_link("Text transform actions")
    end

    visit admin_text_transform_actions_path
    expect(page).to have_text("[Error 404]")
  end
end
