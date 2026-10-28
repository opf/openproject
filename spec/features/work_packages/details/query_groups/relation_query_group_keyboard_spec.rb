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

RSpec.describe "Relation query group keyboard navigation", :js do
  include_context "with axe on Cuprite"

  let(:user) { create(:admin) }
  let(:type) do
    create(:type_with_relation_query_group).tap do |type|
      variant = type.default_variant
      variant.attribute_groups = [[:people, %i[responsible]], variant.attribute_groups.last]
      variant.save!
    end
  end
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) { create(:work_package, project:, type:, subject: "Keyboard parent") }
  let!(:children) do
    (1..3).map { |n| create(:work_package, project:, type:, parent: work_package, subject: "Keyboard child #{n}") }
  end
  let!(:grandchild) { create(:work_package, project:, type:, parent: children.first, subject: "Keyboard grandchild") }
  let!(:orphan) { create(:work_package, project:, type:, subject: "Keyboard orphan") }

  let(:list_query) do
    create(:query, project:, user:).tap do |query|
      query.add_filter("id", "=", [work_package.id.to_s])
      query.save!
    end
  end

  let(:rows) { children }
  let(:group_states) do
    [
      lambda {
        wp_table.press_keys(%i[shift space])
        wp_table.treegrid.find(:row, rows.first.subject, aria: { selected: true })
      },
      lambda {
        wp_table.table_container.click_button("Create new child")
        wp_table.edit_field(nil, :subject).expect_active!
      }
    ]
  end
  let(:split_view) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
  let(:list) { Pages::WorkPackagesTable.new(project) }
  let(:wp_table) do
    Pages::EmbeddedWorkPackagesTable.new(
      find("wp-single-view .work-packages-embedded-view--container"),
      entry_control: -> { split_view.edit_field(:responsible).display_element },
      table_name: "EMBEDDED TABLE FOR PARENT"
    )
  end

  before do
    work_package.status.update_attribute :is_default, true
    work_package.priority.update_attribute :is_default, true

    login_as user
    split_view.visit_query(list_query)
    split_view.ensure_page_loaded
    wp_table.expect_work_package_listed(*rows)
    wp_table.table_container.find_button("Add child")
    list.expect_work_package_listed(work_package)
    wait_for_network_idle
  end

  it_behaves_like "an embedded keyboard table", editable: true do
    let(:first_row_controls) { [rows.first.id.to_s, "Remove child"] }
    let(:next_control) { { role: :button, name: "Create new child" } }
    let(:axe_states) { group_states }
  end

  it "keeps the main list free of axe violations in the group's prepared states" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)
    expect(page).to be_axe_clean.within(list.axe_scope)

    group_states.each do |state|
      instance_exec(&state)
      expect(page).to be_axe_clean.within(list.axe_scope)
    end
  end

  it "reaches the group's first row with Tab from the main list" do
    list.tab_into_table
    list.expect_focus_on_row(work_package)

    wp_table.tab_until_focused(wp_table.entry_control)

    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_row(rows.first)
    list.expect_focus_outside_table
  end

  it "focuses Remove child with Enter on the unlink cell and removes the child only on a second Enter" do
    wp_table.focus_cell_by_keyboard(rows.first, :priority)
    wp_table.press_keys(:right)

    wp_table.press_keys(:enter)
    wp_table.expect_focus_on_control(rows.first, "Remove child")
    wait_for_network_idle
    wp_table.expect_work_package_listed(rows.first)

    expect(page).to have_element(:"tool-tip", text: "Remove child")
    wp_table.press_keys(:escape)
    expect(page).to have_no_element(:"tool-tip", text: "Remove child")
    wp_table.expect_focus_on_control(rows.first, "Remove child")
    wait_for_network_idle
    wp_table.expect_work_package_listed(rows.first)

    wp_table.press_keys(:enter)
    wp_table.ensure_work_package_not_listed!(rows.first)
    wp_table.expect_work_package_listed(*rows.drop(1))
    wp_table.expect_focus_on_row(rows.second)
  end

  it "keeps repeated unlink hints distinct and working after adding a child" do
    rows.each do |child|
      wp_table.row(child).hover
      expect(wp_table.row(child)).to have_selector(:link, accessible_name: "Remove child", accessible_description: "",
                                                          exact: true)
      expect(wp_table.row(child)).to have_link(child.id.to_s, accessible_description: "", exact: true)
    end

    wp_table.focus_row_by_keyboard(rows.first)
    wp_table.press_keys(%i[shift space], :tab, :tab)
    wp_table.expect_focus_on_control(rows.first, "Remove child")
    expect(page).to have_element(:"tool-tip", text: "Remove child")
    wp_table.press_keys(:escape)
    expect(page).to have_no_element(:"tool-tip", text: "Remove child")
    wp_table.expect_selected_rows(rows.first, among: rows)
    wp_table.expect_focus_on_control(rows.first, "Remove child")

    wp_table.reference_work_package(orphan)
    wp_table.expect_work_package_listed(*rows, orphan)
    wp_table.row(rows.first).hover
    replacement = wp_table.row(rows.first).find(:link, accessible_name: "Remove child", exact: true)
    replacement.hover
    expect(page).to have_element(:"tool-tip", text: "Remove child", count: 1)
    wp_table.press_keys(:escape)
    expect(page).to have_no_element(:"tool-tip", text: "Remove child")
    wait_for_network_idle
    wp_table.expect_work_package_listed(*rows, orphan)

    wp_table.row(rows.second).find(:link, rows.second.id.to_s, exact: true).click
    Pages::FullWorkPackage.new(rows.second, project).expect_attributes(Subject: rows.second.subject)
  end

  it "returns focus to Add child when adding an existing child is cancelled" do
    wp_table.tab_into_table
    wp_table.tab_until_focused(wp_table.table_container.find_button("Add child"), bound: 8)

    wp_table.press_keys(:enter)
    expect(page).to have_field(accessible_name: "Search", focused: true)
    wp_table.press_keys(:tab)
    expect(wp_table.table_container).to have_button("Abort", focused: true)
    wp_table.press_keys(:enter)

    expect(page).to have_no_test_selector("wp-relations-autocomplete")
    expect(wp_table.table_container).to have_selector(:button, accessible_name: "Add child", focused: true)
  end

  it "returns focus to Add child after adding an existing child" do
    wp_table.tab_into_table
    wp_table.tab_until_focused(wp_table.table_container.find_button("Add child"), bound: 8)

    wp_table.press_keys(:enter)
    expect(page).to have_field(accessible_name: "Search", focused: true)
    wp_table.select_autocomplete(page.find_test_selector("wp-relations-autocomplete"),
                                 query: orphan.subject,
                                 results_selector: ".ng-dropdown-panel-items")

    wp_table.expect_work_package_listed(orphan)
    expect(wp_table.table_container).to have_selector(:button, accessible_name: "Add child", focused: true)
  end

  it "offers no hierarchy toggle and moves to the first cell with Arrow Right on a row with children" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.press_keys(:right)

    wp_table.expect_focus_on_cell(rows.first, :id)
    expect(wp_table.table_container).to have_no_css(".hierarchy-header--icon")
    expect(wp_table.treegrid).to have_no_selector(:element, "tr", "aria-expanded": /./, visible: :all)
    wp_table.ensure_work_package_not_listed!(grandchild)
  end

  it "numbers the rows of the group" do
    wp_table.tab_into_table
    wp_table.expect_focus_on_row(rows.first)

    wp_table.expect_row_positions(rowcount: 5, rows: [1, 2, 3, 4, 5])
  end
end
