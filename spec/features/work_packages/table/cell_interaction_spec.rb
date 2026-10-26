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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package table cell interaction", :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end

  let!(:parent) { create(:work_package, project:, subject: "Charlie parent") }
  let!(:child) { create(:work_package, project:, parent:, subject: "Alpha child") }
  let!(:sibling) { create(:work_package, project:, subject: "Bravo sibling") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_order(parent, child, sibling)
    wp_table.expect_inline_create_button
  end

  it "opens the ID link with Enter in the full-page view" do
    wp_table.focus_cell_by_keyboard(sibling, :id)

    wp_table.press_keys(:enter)

    expect(page).to have_css(".work-packages--show-view")
  end

  it "returns a walked details link to its row origin" do
    wp_table.focus_row_by_keyboard(sibling)
    wp_table.press_keys(:tab, :tab)
    wp_table.expect_focus_on_control(sibling, "Open details view")

    wp_table.press_keys(:enter)

    split = Pages::PrimerizedSplitWorkPackage.new(sibling)
    split.expect_attributes Subject: sibling.subject
    wp_table.expect_focus_on_row(sibling)
  end

  it "returns a walked context menu to the cell where the walk began" do
    menu = Components::WorkPackages::ContextMenu.new
    wp_table.focus_cell_by_keyboard(sibling, :subject)
    wp_table.press_keys(:tab, :tab)
    wp_table.expect_focus_on_control(sibling, "Open context menu")
    wp_table.press_keys(:enter)
    menu.expect_open
    expect(page).to have_selector(:menuitem, focused: true)

    wp_table.press_keys(:escape)
    menu.expect_closed
    wp_table.expect_focus_on_cell(sibling, :subject)
  end

  it "opens mixed-cell editors with Enter and F2 and walks the hierarchy toggle" do
    wp_table.focus_cell_by_keyboard(parent, :subject)
    wp_table.press_keys(:enter)
    field = wp_table.edit_field(parent, :subject)
    field.expect_active!
    expect(page).to have_css(wp_table.row_selector(child))
    field.cancel_by_escape

    wp_table.press_keys(:f2)
    field.expect_active!
    expect(page).to have_css(wp_table.row_selector(child))
    field.cancel_by_escape

    wp_table.focus_row_by_keyboard(parent)
    wp_table.press_keys(:tab)
    expect(page).to have_link(parent.id.to_s, focused: true)
    wp_table.press_keys(:tab)
    expect(page).to have_css("#{wp_table.row_selector(parent)} .wp-table--hierarchy-indicator[role='button']",
                             focused: true)
  end

  it "parks and re-engages an editor across a native table exit" do
    wp_table.focus_cell_by_keyboard(sibling, :subject)
    wp_table.press_keys(:enter)
    field = wp_table.edit_field(sibling, :subject)
    field.input_element.set("Parked draft")

    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_cell(sibling, :subject)
    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_control(sibling, "Open details view")
    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_control(sibling, "Open context menu")
    wp_table.press_keys(:tab)
    expect(page).to have_button("Create new work package", focused: true)

    wp_table.press_keys(%i[shift tab])
    wp_table.expect_focus_on_cell(sibling, :subject)
    wp_table.press_keys(:enter)
    expect(page).to have_focus_on("##{field.input_element[:id]}")
    expect(field.input_element.value).to eq("Parked draft")

    wp_table.press_keys(%i[shift tab])
    wp_table.expect_focus_on_cell(sibling, :subject)
    wp_table.press_keys(:f2)
    expect(page).to have_focus_on("##{field.input_element[:id]}")
    expect(field.input_element.value).to eq("Parked draft")
  end
end
