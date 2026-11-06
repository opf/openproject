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

RSpec.describe "Accessible work package table tooltips", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin, firstname: "Taylor", lastname: "Tooltip") }
  let!(:parent) do
    create(:work_package, project:, subject: "Tooltip parent", assigned_to: user, estimated_hours: 3,
                          derived_estimated_hours: 5, done_ratio: 0, derived_done_ratio: 0)
  end
  let!(:child) { create(:work_package, project:, parent:, subject: "Tooltip child", estimated_hours: 2) }
  let(:query) do
    create(:query, user:, project:, column_names: %w[id subject assigned_to estimated_hours done_ratio spent_hours],
                   show_hierarchies: false)
  end
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }

  before do
    login_as(user)
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(parent, child)
    wp_table.expect_inline_create_button
  end

  it "shows action hints on keyboard focus and dismisses the hint before clearing selection" do
    wp_table.focus_row_by_keyboard(parent)
    wp_table.press_keys(%i[shift space])
    wp_table.expect_selected_rows(parent, among: [parent, child])

    wp_table.tab_until_focused(wp_table.row(parent).find(:link, accessible_name: "Open details view", exact: true))
    wp_table.expect_focus_on_control(parent, "Open details view")
    expect(wp_table.row(parent)).to have_selector(:link, accessible_name: "Open details view",
                                                         accessible_description: "", exact: true)
    expect(page).to have_element(:"tool-tip", text: "Open details view")

    wp_table.press_keys(:escape)
    expect(page).to have_no_element(:"tool-tip", text: "Open details view")
    wp_table.expect_focus_on_control(parent, "Open details view")
    wp_table.expect_selected_rows(parent, among: [parent, child])

    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_control(parent, "Open context menu")
    expect(page).to have_element(:"tool-tip", text: "Open context menu")

    wp_table.press_keys(:escape)
    wp_table.expect_selected_rows(parent, among: [parent, child])

    wp_table.press_keys(:enter)
    context_menu.expect_open

    wp_table.press_keys(:escape)
    context_menu.expect_closed

    wp_table.focus_cell_by_keyboard(parent, :subject)
    wp_table.tab_until_focused(wp_table.row(parent).find(:link, accessible_name: "Open details view", exact: true))
    wp_table.press_keys(:enter)
    Pages::PrimerizedSplitWorkPackage.new(parent, project).expect_attributes(Subject: parent.subject)
  end

  it "describes values without repeating their names or the ID and principal hints" do
    within(wp_table.row(parent)) do
      expect(page).to have_selector(:role, "rowheader", accessible_name: "Tooltip parent", exact: true)

      find(:link, accessible_name: parent.id.to_s, accessible_description: "", exact: true).hover
      expect(page).to have_no_element(:"tool-tip")

      find(".op-principal--name", text: "Taylor Tooltip", exact_text: true).hover
      expect(page).to have_no_element(:"tool-tip")

      expect(page).to have_selector(:link, accessible_name: "0h",
                                           accessible_description: "Show spent time for this work package", exact: true)
      expect(page).to have_selector(:link, accessible_name: "Log time", accessible_description: "", exact: true)
      expect(page).to have_selector(:link, accessible_name: "Σ 5h", accessible_description: "(value derived from children)",
                                           exact: true)
      expect(page).to have_selector(:link, accessible_name: "Σ 0%", accessible_description: "(value derived from children)",
                                           exact: true)
    end

    Components::WorkPackages::Columns.new.remove("Subject")
    expect(wp_table.row(parent)).to have_selector(:role, "rowheader", accessible_name: parent.id.to_s, exact: true)
  end

  it "keeps visible action tooltips usable at desktop and narrow table widths" do
    original_size = page.current_window.size

    [1440, 900].each do |width|
      page.current_window.resize_to(width, 900)
      wp_table.row(parent).hover

      control = wp_table.row(parent).find(:link, accessible_name: "Open context menu", accessible_description: "", exact: true)
      control.hover
      expect(page).to have_element(:"tool-tip", text: "Open context menu")

      control.click
      context_menu.expect_open

      wp_table.press_keys(:escape)
      context_menu.expect_closed
    end
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end
end
