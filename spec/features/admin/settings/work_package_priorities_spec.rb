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

RSpec.describe "Work package priorities", :js do
  include Flash::Expectations
  include EnumerationAdminHelpers

  current_user { create(:admin) }
  let!(:default_priority) { create(:issue_priority, is_default: true, name: "Normal") }

  def enumeration_list_selector = "#admin-enumerations-index-component"
  def enumeration_actions_label = "Actions"

  def within_enumeration_item(priority, &)
    page.within("#admin-enumerations-item-component-#{priority.id}", &)
  end

  def drag_priority(priority, after:)
    handle = enumeration_drag_handle(priority)
    target = enumeration_row(after)
    offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

    perform_native_drag(source: handle, target:, offset_y: offset_y.round)

    # Assert Pragmatic DnD tore down its own honey-pot overlay, so a regression
    # leaving it stuck is caught here rather than as an unrelated click failure.
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
  end

  it "can be managed (created, updated, deleted)" do
    visit admin_settings_work_package_priorities_path

    within_enumeration_item(default_priority) do
      expect(page).to have_content("Normal")
      expect(page).to have_content("Default")
    end

    page.find_test_selector("add-enumeration-button").click

    fill_in "Name", with: "Immediate"
    check "Default"
    click_on("Save")

    expect_and_dismiss_flash(message: "Successful update.")

    # we are redirected back to the index page
    expect(page).to have_current_path(admin_settings_work_package_priorities_path)

    new_priority = IssuePriority.last

    # The new priority is shown in the list as the default priority
    within_enumeration_item(new_priority) do
      expect(page).to have_content("Immediate")
      expect(page).to have_content("Default")
    end

    # Since the new priority is now the default, the former default looses that flag
    within_enumeration_item(default_priority) do
      expect(page).to have_content("Normal")
      expect(page).to have_no_content("Default")
    end

    # It allows editing (Regression #62459)
    click_link "Immediate"

    fill_in "Name", with: "Urgent"
    click_on("Save")

    expect_and_dismiss_flash(message: "Successful update.")

    within_enumeration_item(new_priority) do
      expect(page).to have_content("Urgent")
      expect(page).to have_content("Default")
    end

    expect(IssuePriority).to exist(name: "Urgent")
    expect(IssuePriority).not_to exist(name: "Immediate")

    # It allows deleting priorities
    within_enumeration_item(new_priority) do
      find(test_selector("op-enumeration--action-menu")).click
      click_button("Delete")
    end

    expect_and_dismiss_flash(message: "Successful deletion.")

    expect(page).to have_no_content("Urgent")

    # Since the old default is deleted another is now the default.
    within_enumeration_item(default_priority) do
      expect(page).to have_content("Normal")
      expect(page).to have_no_content("Default")
    end
  end

  context "with three priorities" do
    let!(:alpha) { create(:issue_priority, name: "Alpha") }
    let!(:beta) { create(:issue_priority, name: "Beta") }
    let!(:gamma) { create(:issue_priority, name: "Gamma") }

    before do
      gamma.move_to_top
      beta.move_to_top
      alpha.move_to_top
    end

    # The second drag runs without a reload on purpose: the sortable root
    # re-registers Pragmatic's drop targets after a morph, and only a drag that
    # follows a completed morph exercises that repair.
    it "reorders by dragging twice across a morph", :selenium do
      visit admin_settings_work_package_priorities_path

      expect_enumeration_order("Alpha", "Beta", "Gamma", "Normal")

      drag_priority(alpha, after: beta)

      expect_enumeration_move_settled("Beta", "Alpha", "Gamma", "Normal")

      drag_priority(beta, after: gamma)

      expect_enumeration_move_settled("Alpha", "Gamma", "Beta", "Normal")

      refresh

      expect_enumeration_order("Alpha", "Gamma", "Beta", "Normal")
    end

    # The moved item's menu is reopened after the morph: only a refreshed menu
    # hides the directions that stopped being available.
    it "reorders through the move menu twice across a morph" do
      visit admin_settings_work_package_priorities_path

      expect_enumeration_order("Alpha", "Beta", "Gamma", "Normal")

      move_enumeration(gamma, I18n.t(:label_sort_highest))

      expect_enumeration_move_settled("Gamma", "Alpha", "Beta", "Normal")

      within_enumeration_move_submenu(gamma) do |submenu|
        expect(submenu).to have_no_selector(:menuitem, I18n.t(:label_sort_highest))
        expect(submenu).to have_no_selector(:menuitem, I18n.t(:label_sort_higher))
        expect(submenu).to have_selector(:menuitem, I18n.t(:label_sort_lower))
        submenu.find(:menuitem, I18n.t(:label_sort_lowest)).click
      end

      expect_enumeration_move_settled("Alpha", "Beta", "Normal", "Gamma")

      refresh

      expect_enumeration_order("Alpha", "Beta", "Normal", "Gamma")
    end

    it "rolls back and reports a move whose anchor no longer exists" do
      visit admin_settings_work_package_priorities_path

      expect_enumeration_order("Alpha", "Beta", "Gamma", "Normal")

      beta.destroy

      move_enumeration(alpha, I18n.t(:label_sort_lower))

      expect_flash(type: :error, message: I18n.t(:error_invalid_list_move_anchor))
      expect(page).to have_no_css("[data-sortable-lists-busy]")
      expect_enumeration_order("Alpha", "Beta", "Gamma", "Normal")
    end
  end

  context "with a single priority" do
    it "hides the Move submenu and renders one separator" do
      visit admin_settings_work_package_priorities_path

      within_enumeration_menu(default_priority) do |menu|
        expect(menu).to have_selector(:menuitem, I18n.t(:button_edit))
        expect(menu).to have_selector(:menuitem, I18n.t(:button_delete))
        expect(menu).to have_no_selector(:menuitem, I18n.t(:button_move))
        expect(menu).to have_css("li.ActionList-sectionDivider", count: 1)
      end
    end
  end
end
