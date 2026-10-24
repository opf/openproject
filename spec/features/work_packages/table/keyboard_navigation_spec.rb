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

RSpec.describe "Work package table keyboard navigation", :js do
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

  it "is one Tab stop and navigates by arrow keys" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(parent)

    wp_table.press_keys(:down, :down, :right)
    wp_table.expect_focus_on_cell(sibling, :id)

    wp_table.press_keys(:right, :up, :up, :up)
    wp_table.expect_focus_on_column_header("Subject")

    wp_table.press_keys(:enter)
    within("#column-context-menu") do
      expect(page).to have_selector(:menuitem, focused: true)
    end
    wp_table.press_keys(:escape)
    expect(page).to have_no_css("#column-context-menu")
    wp_table.expect_focus_on_column_header("Subject")

    wp_table.press_keys(:down)
    wp_table.expect_focus_on_cell(parent, :subject)

    wp_table.press_keys(:up)
    wp_table.expect_focus_on_column_header("Subject")
    wp_table.press_keys(:enter)
    within "#column-context-menu" do
      click_on "Sort ascending"
    end
    expect(page).to have_css(".generic-table--sort-header #subject.asc")
    wp_table.expect_work_package_order(sibling, parent, child)

    # The column menu drops focus to body after an action until DREAM-894.
    wp_table.tab_into_table
    wp_table.expect_focus_on_column_header("Subject")

    wp_table.press_keys(:down)
    wp_table.expect_focus_on_cell(sibling, :subject)

    wp_table.press_keys(%i[shift tab])
    wp_table.expect_focus_outside_table
  end

  it "leaves the table forward with one Tab from the last row" do
    wp_table.tab_into_table
    wp_table.press_keys(:down, :down)
    wp_table.expect_focus_on_row(sibling)

    wp_table.press_keys(:tab)

    expect(page).to have_button("Create new work package", focused: true)
  end

  it "selects only the row Enter is pressed on" do
    wp_table.focus_row_by_keyboard(parent)
    wp_table.press_keys(:enter)
    expect(page).to have_css("#{wp_table.row_selector(parent)}.-checked")

    wp_table.press_keys(:down, :enter)

    expect(page).to have_css("#{wp_table.row_selector(child)}.-checked")
    expect(page).to have_no_css("#{wp_table.row_selector(parent)}.-checked")
    expect(page).to have_css(".wp-table--row.-checked", count: 1)
  end

  it "returns focus to the cell when an inline editor is cancelled" do
    subject_field = wp_table.edit_field(sibling, :subject)
    subject_field.activate!
    subject_field.cancel_by_escape

    subject_field.expect_inactive!
    wp_table.expect_focus_on_cell(sibling, :subject)
  end

  it "saves a subject through the native keyboard editor and returns focus" do
    wp_table.focus_cell_by_keyboard(sibling, :subject)
    wp_table.press_keys(:enter)
    field = wp_table.edit_field(sibling, :subject)
    field.expect_active!
    field.input_element.set("Saved by native keyboard")
    wp_table.press_keys(:enter)

    field.expect_inactive!
    field.expect_display_value("Saved by native keyboard")
    wp_table.expect_focus_on_cell(sibling, :subject)
  end

  it "reaches a cell by keyboard" do
    wp_table.focus_cell_by_keyboard(child, :subject)
    wp_table.expect_focus_on_cell(child, :subject)
  end

  context "with an exclusion information icon" do
    let(:excluded_status) { create(:status, :excluded_from_totals) }
    let!(:excluded) do
      create(:work_package, project:, status: excluded_status, subject: "Delta excluded", estimated_hours: 8)
    end
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject estimated_hours], display_sums: true)
    end

    it "leaves the grid with one Tab after a custom element renders a Tab stop" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(excluded)
      wp_table.expect_inline_create_button
      expect(page).to have_css("opce-exclusion-info [tabindex]", visible: :all)

      wp_table.focus_row_by_keyboard(excluded)
      wp_table.press_keys(:tab)

      expect(page).to have_button("Create new work package", focused: true)
    end

    it "moves down from the last row into the totals row" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(excluded, sibling, child, parent)

      wp_table.focus_cell_by_keyboard(parent, :estimated_time)
      wp_table.press_keys(:down)

      wp_table.expect_focus_on_totals_cell(:estimated_time)
    end
  end
end
