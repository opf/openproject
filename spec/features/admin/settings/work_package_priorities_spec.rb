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

  current_user { create(:admin) }
  let!(:default_priority) { create(:issue_priority, is_default: true, name: "Normal") }

  def within_enumeration_item(priority, &)
    page.within("#admin-enumerations-item-component-#{priority.id}", &)
  end

  def priority_names_in_order
    page.all("#admin-enumerations-index-component a[href$='/edit']").map(&:text)
  end

  def open_priority_menu(priority)
    within_enumeration_item(priority) do
      click_on accessible_name: "Actions"
    end
  end

  def move_priority(priority, direction_label)
    open_priority_menu(priority)
    click_on I18n.t(:button_move)
    click_on direction_label
  end

  def drag_priority(priority, after:)
    handle = find("#admin-enumerations-item-component-#{priority.id} .DragHandle")
    target = find("#admin-enumerations-item-component-#{after.id}")
    offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

    perform_native_drag(source: handle, target:, offset_y: offset_y.round)

    # Assert Pragmatic DnD tore down its own honey-pot overlay, so a regression
    # leaving it stuck is caught here rather than as an unrelated click failure.
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
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

      wait_for { priority_names_in_order }.to eq(%w[Alpha Beta Gamma Normal])

      drag_priority(alpha, after: beta)

      wait_for { priority_names_in_order }.to eq(%w[Beta Alpha Gamma Normal])
      expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
      expect(page).to have_no_css("[data-sortable-lists-busy]")

      drag_priority(beta, after: gamma)

      wait_for { priority_names_in_order }.to eq(%w[Alpha Gamma Beta Normal])
      expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
      expect(page).to have_no_css("[data-sortable-lists-busy]")

      refresh

      wait_for { priority_names_in_order }.to eq(%w[Alpha Gamma Beta Normal])
    end

    it "reorders through the move menu twice across a morph" do
      visit admin_settings_work_package_priorities_path

      wait_for { priority_names_in_order }.to eq(%w[Alpha Beta Gamma Normal])

      move_priority(gamma, I18n.t(:label_sort_highest))

      wait_for { priority_names_in_order }.to eq(%w[Gamma Alpha Beta Normal])
      expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
      expect(page).to have_no_css("[data-sortable-lists-busy]")

      move_priority(alpha, I18n.t(:label_sort_lowest))

      wait_for { priority_names_in_order }.to eq(%w[Gamma Beta Normal Alpha])
      expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
      expect(page).to have_no_css("[data-sortable-lists-busy]")

      refresh

      wait_for { priority_names_in_order }.to eq(%w[Gamma Beta Normal Alpha])
    end

    it "rolls back and reports a move whose anchor no longer exists" do
      visit admin_settings_work_package_priorities_path

      wait_for { priority_names_in_order }.to eq(%w[Alpha Beta Gamma Normal])

      beta.destroy

      move_priority(alpha, I18n.t(:label_sort_lower))

      expect_flash(type: :error, message: I18n.t(:error_invalid_list_move_anchor))
      expect(page).to have_no_css("[data-sortable-lists-busy]")
      wait_for { priority_names_in_order }.to eq(%w[Alpha Beta Gamma Normal])
    end
  end

  context "with a single priority" do
    it "hides the move directions and renders one separator" do
      visit admin_settings_work_package_priorities_path

      open_priority_menu(default_priority)

      expect(page).to have_link(I18n.t(:button_edit))
      expect(page).to have_button(I18n.t(:button_delete))
      expect(page).to have_no_text(I18n.t(:button_move))
      expect(page).to have_no_button(I18n.t(:label_sort_highest))
      expect(page).to have_no_button(I18n.t(:label_sort_higher))
      expect(page).to have_no_button(I18n.t(:label_sort_lower))
      expect(page).to have_no_button(I18n.t(:label_sort_lowest))
      expect(page).to have_css("li.ActionList-sectionDivider", count: 1)
    end
  end
end
