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
require "support/shared/embedded_keyboard_table_examples"

require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "BCF list keyboard navigation", :js, with_config: { edition: "bim" } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  shared_let(:user) { create(:admin) }
  shared_let(:work_packages) do
    (1..5).map { |n| create(:work_package, project:, subject: "BCF keyboard #{n}") }
  end

  let(:view_name) { "Table" }
  let(:rows) { work_packages.sort_by(&:id).reverse }
  let(:bcf_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:entry_control) do
    if view_name == "Table"
      -> { find(:button, "More actions") }
    else
      -> { find(:link, "Use this link to upload and manage your IFC models") }
    end
  end
  let(:wp_table) { Pages::EmbeddedWorkPackagesTable.new(page, project, entry_control:) }

  def expect_selection(*selected)
    wp_table.expect_selected_rows(*selected, among: rows)
  end

  def wait_for_list_to_settle
    expect(page).to have_css(".loading-indicator--background")
    expect(page).to have_no_css(".loading-indicator--background", wait: 10)
  end

  before do
    login_as user
    bcf_page.visit!
    bcf_page.expect_work_package_listed(*rows)
    bcf_page.switch_view view_name
    wait_for_list_to_settle
    wp_table.expect_work_package_listed(*rows)
    wp_table.expect_inline_create_button
  end

  it_behaves_like "an embedded keyboard table", editable: true do
    let(:first_row_controls) { [rows.first.id.to_s, "Open details view", "Open context menu"] }
    let(:next_control) { { role: :button, name: "Create new work package" } }
    let(:context_menu_enabled) { true }
    let(:axe_states) do
      [
        lambda {
          wp_table.press_keys(%i[shift f10])
          context_menu.expect_open
          wp_table.press_keys(:escape)
          context_menu.expect_closed
        }
      ]
    end
  end

  context "when displayed as split table" do
    let(:view_name) { "Viewer and table" }

    it_behaves_like "an embedded keyboard table", editable: true, letter_shortcuts: false do
      let(:first_row_controls) { [rows.first.id.to_s, "Open details view", "Open context menu"] }
      let(:next_control) { { role: :button, name: "Create new work package" } }
      let(:context_menu_enabled) { true }
    end
  end

  it "numbers the rows of the flat list" do
    wp_table.expect_row_positions(rowcount: rows.size + 2, rows: (1..(rows.size + 2)).to_a)
  end

  it "opens the context menu for the selection with Shift+F10 and the Menu key" do
    wp_table.focus_row_by_keyboard(rows.first)
    wp_table.press_keys(%i[shift space], %i[shift down])
    expect_selection(rows.first, rows.second)

    wp_table.press_keys(%i[shift f10])
    context_menu.expect_open
    expect(page).to have_selector(:menu, count: 1)
    expect(page).to have_selector(:menuitem, "Bulk delete")
    wp_table.press_keys(:escape)
    context_menu.expect_closed

    wp_table.press_menu_key
    context_menu.expect_open
    expect(page).to have_selector(:menuitem, "Bulk delete")
  end

  it "activates a row with Enter like a click without opening the details view" do
    wp_table.focus_row_by_keyboard(rows.second)
    wp_table.press_keys(:enter)

    expect_selection(rows.second)
    expect(page).to have_no_current_path(/\/bcf\/details/, ignore_query: true)
  end

  it "returns focus to the originating row when the menu is closed with Escape" do
    wp_table.focus_row_by_keyboard(rows.third)

    wp_table.press_keys(%i[shift f10])
    context_menu.expect_open
    wp_table.press_keys(:escape)

    context_menu.expect_closed
    wp_table.expect_focus_on_row(rows.third)
  end

  it "replaces the selection with the unselected row the menu opens on and keeps it after Escape" do
    wp_table.focus_row_by_keyboard(rows.first)
    wp_table.press_keys(%i[shift space], %i[shift down], %i[shift down])
    live_region = Components::LiveRegion.new
    live_region.expect_announcement("3 work packages selected.")
    expect_selection(*rows.first(3))

    wp_table.press_keys(:down, :down)
    wp_table.expect_focus_on_row(rows.fifth)
    wp_table.press_keys(%i[shift f10])
    context_menu.expect_open
    expect_selection(rows.fifth)
    live_region.expect_announcement("1 work package selected.")

    wp_table.press_keys(:escape)
    context_menu.expect_closed
    wp_table.expect_focus_on_row(rows.fifth)
    expect_selection(rows.fifth)
    live_region.expect_announcement("1 work package selected.")
  end
end
