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

RSpec.shared_examples "an embedded keyboard table" do |editable: true, drag_and_drop_enabled: false|
  include_context "with axe on Cuprite"

  let(:context_menu_enabled) { false }
  let(:axe_states) { [] }
  let(:live_region) { Components::LiveRegion.new }
  let(:select_all_chord) { [BrowserPlatform.multi_select_modifier(page), "a"] }

  def expect_selected(*selected)
    wp_table.expect_selected_rows(*selected, among: rows)
  end

  it "enters on the first row with Tab and leaves to the entry control with Shift+Tab" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(%i[shift tab])

    expect(wp_table.entry_control).to match_selector(:css, ":focus")
  end

  it "walks the first row's controls with Tab, leaves to the next control and re-enters on the row" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    first_row_controls.each do |name|
      wp_table.press_keys(:tab)
      wp_table.expect_focus_on_control(rows.first, name)
    end

    wp_table.press_keys(:tab)
    if next_control.key?(:element)
      expect(page).to have_element(next_control[:element], text: next_control[:text], focused: true)
    else
      expect(page).to have_selector(next_control[:role], next_control[:name], focused: true)
    end
    wp_table.expect_focus_outside_table

    wp_table.press_keys(%i[shift tab])
    wp_table.expect_focus_on_row(rows.first)
  end

  it "moves between rows and cells and to the header with the arrow keys" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(:down)
    wp_table.expect_focus_on_row(rows.second)
    wp_table.press_keys(:up)
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(:right)
    wp_table.expect_focus_on_cell(rows.first, :id)
    wp_table.press_keys(:left)
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(%i[control home])
    expect(wp_table.table_container).to have_css("thead tr", focused: true)
  end

  it "selects rows with Shift+Space and Shift+Down, announces Select All and clears with Escape" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)
    expect_selected

    wp_table.press_keys(%i[shift space])
    expect_selected(rows.first)

    wp_table.press_keys(%i[shift down])
    wp_table.expect_focus_on_row(rows.second)
    expect_selected(rows.first, rows.second)

    wp_table.press_keys(select_all_chord)
    live_region.expect_announcement("All #{rows.size} work packages on this page selected.")
    expect_selected(*rows)

    wp_table.press_keys(:escape)
    live_region.expect_announcement("Selection cleared.")
    expect_selected
  end

  it "handles Shift+F10 according to whether the context menu is enabled" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(%i[shift f10])

    if context_menu_enabled
      expect(page).to have_css("#work-package-context-menu")
      wp_table.press_keys(:escape)
      expect(page).to have_no_css("#work-package-context-menu")
      wp_table.expect_focus_on_row(rows.first)
    else
      wp_table.press_keys(:down)
      wp_table.expect_focus_on_row(rows.second)
      expect(page).to have_no_css("#work-package-context-menu")
    end
  end

  it "renders no expandable row in a flat table" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    expect(wp_table.treegrid).to have_no_selector(:element, "tr", "aria-expanded": /./, visible: :all)
  end

  unless drag_and_drop_enabled
    it "renders no drag handle" do
      wp_table.tab_into_table
      wp_table.expect_focus_on_row(rows.first)

      expect(wp_table.table_container).to have_no_css(".wp-table--drag-and-drop-handle")
    end
  end

  if editable
    it "edits the subject through the keyboard editor and returns focus to the cell" do
      wp_table.focus_cell_by_keyboard(rows.first, :subject)
      wp_table.press_keys(:enter)
      field = wp_table.edit_field(rows.first, :subject)
      field.expect_active!
      field.input_element.set("Saved by embedded keyboard")
      wp_table.press_keys(:enter)

      field.expect_inactive!
      field.expect_display_value("Saved by embedded keyboard")
      wp_table.expect_focus_on_cell(rows.first, :subject)
    end
  end

  it "has no axe violations in the prepared states" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    expect(page).to be_axe_clean.within(wp_table.axe_scope)

    axe_states.each do |state|
      instance_exec(&state)
      expect(page).to be_axe_clean.within(wp_table.axe_scope)
    end
  end
end
