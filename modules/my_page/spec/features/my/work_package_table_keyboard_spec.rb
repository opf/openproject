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

require_relative "../../support/pages/my/page"

RSpec.describe "Work package table widgets keyboard navigation on my page", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:other_user) { create(:user) }
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages save_queries] })
  end
  shared_let(:assigned_work_packages) do
    (1..3).map do |n|
      create(:work_package, project:, subject: "Assigned keyboard #{n}", author: other_user, assigned_to: user)
    end
  end
  shared_let(:created_work_packages) do
    (1..3).map do |n|
      create(:work_package, project:, subject: "Created keyboard #{n}", author: user)
    end
  end

  let(:assigned_title) { "Work packages assigned to me" }
  let(:created_title) { "Work packages created by me" }
  let(:rows) { assigned_work_packages.sort_by(&:id) }
  let(:created_rows) { created_work_packages.sort_by(&:id) }
  let(:wp_table) do
    Pages::EmbeddedWorkPackagesTable.new(
      find(".grid--area.-widgeted:nth-of-type(1)"),
      entry_control: -> { find(:link, accessible_name: "Show menu options for #{assigned_title} widget") },
      table_name: assigned_title
    )
  end
  let(:created_table) do
    Pages::EmbeddedWorkPackagesTable.new(
      find(".grid--area.-widgeted:nth-of-type(2)"),
      entry_control: -> { find(:link, accessible_name: "Show menu options for #{created_title} widget") },
      table_name: created_title
    )
  end

  before do
    login_as user
    Pages::My::Page.new.visit!
    wp_table.expect_work_package_listed(*rows)
    created_table.expect_work_package_listed(*created_rows)
    wp_table.expect_inline_create_button
    created_table.expect_inline_create_button
  end

  it_behaves_like "an embedded keyboard table", editable: true do
    let(:first_row_controls) { [rows.first.id.to_s] }
    let(:next_control) { { role: :button, name: "Create new work package" } }
    let(:axe_states) { [-> { wp_table.press_keys(%i[shift space]) }] }
  end

  it "passes from the first widget through its successors to the first row of the second widget and back" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_control(rows.first, rows.first.id.to_s)

    wp_table.press_keys(:tab)
    expect(page).to have_button("Create new work package", focused: true)
    wp_table.expect_focus_outside_table

    wp_table.press_keys(:tab)
    expect(page).to have_field(accessible_name: "Click to edit title of this view. Press enter to save.", focused: true)

    wp_table.press_keys(:tab)
    expect(created_table.entry_control).to match_selector(:css, ":focus")

    wp_table.press_keys(:tab)
    created_table.expect_focus_on_row(created_rows.first)
    wp_table.expect_focus_outside_table

    wp_table.press_keys(%i[shift tab])
    expect(created_table.entry_control).to match_selector(:css, ":focus")

    wp_table.press_keys(:tab)
    created_table.expect_focus_on_row(created_rows.first)
  end

  it "returns from the second widget to the remembered row of the first" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)
    wp_table.press_keys(:down)
    wp_table.expect_focus_on_row(rows.second)

    created_table.tab_into_table
    created_table.expect_focus_on_row(created_rows.first)

    created_table.press_keys(%i[shift tab])
    expect(created_table.entry_control).to match_selector(:css, ":focus")
    created_table.press_keys(%i[shift tab])
    expect(page).to have_field(accessible_name: "Click to edit title of this view. Press enter to save.", focused: true)
    created_table.press_keys(%i[shift tab])
    expect(page).to have_button("Create new work package", focused: true)
    created_table.press_keys(%i[shift tab])

    wp_table.expect_focus_on_row(rows.second)
  end

  it "selects all rows only in the table that has focus" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)
    wp_table.press_keys([BrowserPlatform.multi_select_modifier(page), "a"])

    expect(wp_table.treegrid).to have_selector(:row, aria: { selected: true }, count: rows.size)
    expect(created_table.treegrid).to have_no_selector(:row, aria: { selected: true })
  end

  it "moves between rows with j without leaving the table that has focus" do
    created_table.tab_into_table
    created_table.expect_focus_on_row(created_rows.first)
    created_table.press_keys(:right)
    created_table.expect_focus_on_cell(created_rows.first, :id)

    created_table.press_keys("j")
    created_table.expect_focus_on_row(created_rows.second)
    wp_table.expect_focus_outside_table
  end
end
