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

RSpec.describe "Work package table treegrid semantics", :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages add_work_packages] })
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  around do |example|
    configuration = Axe::Configuration.instance
    previous_legacy_mode = configuration.legacy_mode
    Capybara::Cuprite::Browser.class_eval do
      define_method(:execute_async_script) do |script, *args|
        evaluate_async(script, 120, *args)
      end
    end
    configuration.legacy_mode = true
    begin
      example.run
    ensure
      configuration.legacy_mode = previous_legacy_mode
    end
  end

  before do
    login_as(user)
  end

  context "in flat mode with an expanded relation column" do
    let!(:parent) { create(:work_package, project:, subject: "Parent task", estimated_hours: 3) }
    let!(:child) { create(:work_package, project:, parent:, subject: "Child task", estimated_hours: 2) }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject relation_child estimated_hours],
                     sort_criteria: [%w[subject asc]], show_hierarchies: false, display_sums: true)
    end

    it "exposes rows, sort, totals, selection and the relation button" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(child, parent)

      expect(treegrid).to match_selector(:table, accessible_description: "Sorted by Subject ascending.", exact: true)
      expect(treegrid).to have_selector(:row, "Subject", aria: { level: 1, selected: nil, expanded: nil })
      expect(treegrid).to have_selector(:columnheader, "Subject", aria: { sort: "ascending" })
      expect(treegrid).to have_selector(:columnheader, "ID", aria: { sort: nil })
      expect(treegrid).to have_selector(:row, "Parent task", aria: { level: 1, selected: false, expanded: nil })
      expect(treegrid).to have_selector(:row, accessible_name: /Total sum/, aria: { level: 1, selected: nil })
      expect(treegrid).to have_selector(:gridcell, accessible_description: "Total sum")
      expect_axe_clean_table

      wp_table.focus_row_by_keyboard(parent)
      wp_table.press_keys(:enter)
      expect(treegrid).to have_selector(:row, "Parent task", aria: { selected: true })
      expect(treegrid).to have_selector(:row, "Child task", aria: { selected: false })
      expect_axe_clean_table

      relations = "Relations in Children for #{parent.formatted_id}"
      find(:button, accessible_name: relations, aria: { expanded: false }).click
      expect(page).to have_button(accessible_name: relations, aria: { expanded: true })
      expect(treegrid).to have_selector(:row, "Child task", aria: { level: 2, selected: false }, count: 1)
      expect(treegrid).to have_selector(:row, "Parent task", aria: { selected: true })
      expect_axe_clean_table

      find(:button, accessible_name: relations, aria: { expanded: true }).click
      expect(page).to have_button(accessible_name: relations, aria: { expanded: false })
      expect(treegrid).to have_no_selector(:element, "tr", aria: { level: 2 }, text: "Child task", visible: :all)
      expect_axe_clean_table

      expect(page).to have_selector(:element, class: "work-packages-tabletimeline--timeline-side",
                                              aria: { hidden: true }, visible: :all)
    end
  end

  context "in grouped mode" do
    let(:foo) { create(:category, project:, name: "Foo") }
    let(:bar) { create(:category, project:, name: "Bar") }
    let!(:alpha) { create(:work_package, project:, category: foo, subject: "Alpha in foo", estimated_hours: 1) }
    let!(:bravo) { create(:work_package, project:, category: foo, subject: "Bravo in foo", estimated_hours: 2) }
    let!(:charlie) { create(:work_package, project:, category: bar, subject: "Charlie in bar", estimated_hours: 4) }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject estimated_hours],
                     group_by: "category", show_hierarchies: false, display_sums: true)
    end

    it "exposes group levels and removes collapsed members from the accessibility tree" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(alpha, bravo, charlie)

      expect(treegrid).to have_selector(:row, "Foo", aria: { level: 1, expanded: true, selected: nil })
      expect(treegrid).to have_selector(:row, "Alpha in foo", aria: { level: 2, selected: false, expanded: nil })
      expect(treegrid).to have_selector(:row, /\bSum\b/, aria: { level: 2, selected: nil, expanded: nil }, count: 2)
      expect(treegrid).to have_selector(:gridcell, accessible_description: "Sum", minimum: 2)
      expect(treegrid).to have_selector(:row, accessible_name: /Total sum/, aria: { level: 1, selected: nil })
      expect_axe_clean_table

      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(:enter)
      expect(treegrid).to have_selector(:row, "Alpha in foo", aria: { selected: true })
      expect_axe_clean_table

      foo_header = treegrid.find(:row, "Foo", aria: { expanded: true })
      foo_sums_key = foo_header["data-occurrence-key"].sub(/:header\z/, ":sums")
      foo_header.find(".expander").click
      expect(treegrid).to have_selector(:row, "Foo", aria: { level: 1, expanded: false })
      foo_members = [alpha, bravo].map { |wp| treegrid.find(wp_table.row_selector(wp), visible: :hidden) }
      foo_sum = treegrid.find("tr[data-occurrence-key='#{foo_sums_key}']", visible: :hidden)
      expect(foo_members.first).to match_selector(:element, aria: { hidden: true, selected: true }, visible: :hidden)
      [*foo_members, foo_sum].each { |row| expect_excluded_from_accessibility_tree(row) }
      expect(treegrid).to have_selector(:row, "Charlie in bar", aria: { level: 2 })
      expect_axe_clean_table

      treegrid.find(:row, "Foo", aria: { expanded: false }).find(".expander").click
      expect(treegrid).to have_selector(:row, "Foo", aria: { level: 1, expanded: true })
      expect(treegrid).to have_selector(:row, "Alpha in foo", aria: { level: 2, selected: true })
      [*foo_members, foo_sum].each { |row| expect_exposed_at_level(row, 2) }
      expect_axe_clean_table
    end
  end

  context "in hierarchy mode" do
    let!(:parent) { create(:work_package, project:, subject: "Alpha parent") }
    let!(:child) { create(:work_package, project:, parent:, subject: "Bravo child") }
    let!(:grandchild) { create(:work_package, project:, parent: child, subject: "Charlie grandchild") }
    let!(:sibling) { create(:work_package, project:, subject: "Delta sibling") }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject], show_hierarchies: true)
    end

    it "exposes levels and expansion and removes collapsed descendants from the accessibility tree" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(parent, child, grandchild, sibling)

      expect(treegrid).to have_selector(:row, "Alpha parent", aria: { level: 1, expanded: true, selected: false })
      expect(treegrid).to have_selector(:row, "Bravo child", aria: { level: 2, expanded: true, selected: false })
      expect(treegrid).to have_selector(:row, "Charlie grandchild",
                                        aria: { level: 3, expanded: nil, selected: false })
      expect(treegrid).to have_selector(:row, "Delta sibling", aria: { level: 1, expanded: nil, selected: false })
      expect_axe_clean_table

      wp_table.focus_row_by_keyboard(grandchild)
      wp_table.press_keys(:enter)
      expect(treegrid).to have_selector(:row, "Charlie grandchild", aria: { selected: true })
      expect_axe_clean_table

      within(treegrid.find(:row, "Alpha parent", aria: { expanded: true })) do
        find(:role, "button", accessible_name: /\AHierarchy level 1, expanded\./).click
      end
      expect(treegrid).to have_selector(:row, "Alpha parent", aria: { level: 1, expanded: false })
      descendants = [child, grandchild].map { |wp| treegrid.find(wp_table.row_selector(wp), visible: :hidden) }
      expect(descendants.last).to match_selector(:element, aria: { hidden: true, selected: true }, visible: :hidden)
      descendants.each { |row| expect_excluded_from_accessibility_tree(row) }
      expect_axe_clean_table

      within(treegrid.find(:row, "Alpha parent", aria: { expanded: false })) do
        find(:role, "button", accessible_name: /\AHierarchy level 1, collapsed\./).click
      end
      expect(treegrid).to have_selector(:row, "Alpha parent", aria: { level: 1, expanded: true })
      expect(treegrid).to have_selector(:row, "Charlie grandchild", aria: { level: 3, selected: true })
      expect_exposed_at_level(descendants.first, 2)
      expect_exposed_at_level(descendants.last, 3)
      expect_axe_clean_table
    end
  end

  context "with empty results" do
    let!(:doomed) { create(:work_package, project:, subject: "Doomed task") }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject], show_hierarchies: false).tap do |q|
        q.add_filter("subject", "~", ["Doomed"])
        q.save!
      end
    end

    it "recovers to the header row when the last row goes and leaves the grid by Tab" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(doomed)

      wp_table.focus_cell_by_keyboard(doomed, :subject)
      wp_table.press_keys(:enter)
      field = wp_table.edit_field(doomed, :subject)
      field.expect_active!
      field.input_element.set("Renamed task")
      wp_table.press_keys(:enter)

      expect(treegrid).to have_selector(:row, "No work packages to display.", aria: { level: 1, selected: nil })
      expect(treegrid).to have_selector(:row, "Create new work package", aria: { level: 1, selected: nil })
      expect_focus_on_header_row
      expect_axe_clean_table

      wp_table.press_keys(:tab)
      expect(page).to have_button("Create new work package", focused: true)

      wp_table.press_keys(%i[shift tab])
      expect_focus_on_header_row
      wp_table.press_keys(%i[shift tab])
      wp_table.expect_focus_outside_table

      wp_table.tab_into_table
      expect_focus_on_header_row
    end
  end

  def treegrid
    find(:table, role: "treegrid", accessible_name: "Work packages")
  end

  def expect_axe_clean_table
    expect(page).to be_axe_clean.within("table.work-package-table")
  end

  def expect_focus_on_header_row
    expect(treegrid).to have_selector(:row, "Subject", aria: { level: 1, selected: nil }, focused: true)
  end

  def accessibility_node(row)
    ferrum_node = row.native.node
    ferrum_node.page.accessibility.partial_tree(node: ferrum_node)
      .find { it.backend_dom_node_id == ferrum_node.description["backendNodeId"] }
  end

  def expect_excluded_from_accessibility_tree(row)
    ax_node = accessibility_node(row)
    expect(ax_node&.ignored?).to be(true), "expected #{row_identity(row)} to be ignored in the AX tree"
  end

  def row_identity(row)
    identity = row["data-work-package-id"] || row["data-occurrence-key"] || row[:id]
    "row #{identity.inspect}"
  end

  def expect_exposed_at_level(row, level)
    ax_node = accessibility_node(row)
    expect(ax_node).not_to be_nil
    expect(ax_node).not_to be_ignored
    expect(ax_node.properties["level"]).to eq(level)
  end
end
