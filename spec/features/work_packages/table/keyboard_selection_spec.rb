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

RSpec.describe "Work package table keyboard selection", :js do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages edit_work_packages add_work_packages delete_work_packages]
           })
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new(bulk_mode: true) }
  let(:live_region) { Components::LiveRegion.new }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:select_all_chord) { [BrowserPlatform.multi_select_modifier(page), "a"] }

  before do
    login_as(user)
  end

  def expect_selection(*selected)
    listed.each do |work_package|
      expect(wp_table.treegrid)
        .to have_selector(:row, work_package.subject, aria: { selected: selected.include?(work_package) })
    end
  end

  context "in a flat table" do
    let!(:alpha) { create(:work_package, project:, subject: "Alpha task") }
    let!(:bravo) { create(:work_package, project:, subject: "Bravo task") }
    let!(:charlie) { create(:work_package, project:, subject: "Charlie task") }
    let!(:delta) { create(:work_package, project:, subject: "Delta task") }
    let!(:echo) { create(:work_package, project:, subject: "Echo task") }
    let(:listed) { [alpha, bravo, charlie, delta, echo] }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject],
                     sort_criteria: [%w[subject asc]], show_hierarchies: false)
    end

    before do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(*listed)
      wp_table.expect_inline_create_button
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:154
    # Divergence: the table toggles with Shift+Space, Backlogs with plain Space.
    it "toggles with Shift+Space from row and cell focus, and deselecting re-bases the anchor" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(:space)
      expect_selection
      wp_table.expect_focus_on_row(bravo)

      wp_table.press_keys(%i[shift space])
      expect_selection(bravo)
      live_region.expect_announcement("1 work package selected.")

      wp_table.press_keys(:right, :right)
      wp_table.expect_focus_on_cell(bravo, :subject)
      wp_table.press_keys(%i[shift space])
      expect_selection
      live_region.expect_announcement("Selection cleared.")

      # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:98
      wp_table.press_keys(:down)
      wp_table.press_keys(%i[shift space])
      wp_table.press_keys(%i[shift space])
      expect_selection

      wp_table.press_keys(%i[shift down])
      expect_selection(charlie, delta)
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:111,190
    it "extends, shrinks and reverses a range from a fixed anchor with Shift+ArrowDown and Shift+ArrowUp" do
      wp_table.focus_row_by_keyboard(charlie)
      wp_table.press_keys(%i[shift space])

      wp_table.press_keys(%i[shift down], %i[shift down])
      wp_table.expect_focus_on_row(echo)
      expect_selection(charlie, delta, echo)

      wp_table.press_keys(%i[shift up])
      expect_selection(charlie, delta)

      wp_table.press_keys(%i[shift up], %i[shift up], %i[shift up])
      wp_table.expect_focus_on_row(alpha)
      expect_selection(alpha, bravo, charlie)
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:181
    it "selects every work package on the page with Ctrl/Cmd+A from a row and from the column header" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(select_all_chord)
      expect_selection(*listed)

      wp_table.press_keys(:escape)
      expect_selection

      wp_table.press_keys(:up, :up, :right)
      wp_table.expect_focus_on_column_header("ID")
      wp_table.press_keys(select_all_chord)
      expect_selection(*listed)
    end

    it "collapses to the first row when Shift+ArrowDown follows a header Select All" do
      wp_table.tab_into_table
      wp_table.press_keys(%i[control home])
      wp_table.press_keys(select_all_chord)
      expect_selection(*listed)

      wp_table.press_keys(%i[shift down])

      wp_table.expect_focus_on_row(alpha)
      expect_selection(alpha)
    end

    it "does not handle Ctrl/Cmd+Shift+A" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys([BrowserPlatform.multi_select_modifier(page), :shift, "a"])

      wp_table.expect_focus_on_row(bravo)
      expect_selection
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:154,168
    it "clears with Escape from inside the table and with focus outside it" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space])
      expect_selection(bravo)
      wp_table.press_keys(:escape)
      expect_selection

      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(bravo, charlie)
      find("li", text: "(1 - 5/5)").click
      wp_table.press_keys(:escape)
      expect_selection
    end

    it "lets an inline editor consume its own Escape before the selection is cleared" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space])
      expect_selection(bravo)

      subject_field = wp_table.edit_field(bravo, :subject)
      subject_field.activate!
      subject_field.cancel_by_escape
      subject_field.expect_inactive!
      expect_selection(bravo)

      wp_table.press_keys(:escape)
      expect_selection
    end

    it "opens one context menu acting on the selection when Shift+F10 is pressed on a selected row" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(bravo, charlie)

      wp_table.press_keys(%i[shift f10])

      context_menu.expect_open
      expect(page).to have_selector(:menu, count: 1)
      context_menu.choose("Bulk delete")
      destroy_modal.expect_listed(bravo, charlie)
      destroy_modal.cancel_deletion
    end

    it "replaces the selection when Shift+F10 is pressed on an unselected row" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space], :down)
      wp_table.expect_focus_on_row(charlie)
      expect_selection(bravo)

      wp_table.press_keys(%i[shift f10])

      context_menu.expect_open
      expect_selection(charlie)
      context_menu.choose("Delete")
      destroy_modal.expect_listed(charlie)
      destroy_modal.cancel_deletion
    end

    it "returns focus to the originating cell when the menu is closed with Escape" do
      wp_table.focus_cell_by_keyboard(delta, :subject)

      wp_table.press_keys(%i[shift f10])
      context_menu.expect_open
      expect(page).to have_selector(:menuitem, focused: true)
      wp_table.press_keys(:escape)

      context_menu.expect_closed
      wp_table.expect_focus_on_cell(delta, :subject)
      expect_selection(delta)
    end

    it "opens the context menu with the Menu key and with Shift+Alt+F10" do
      wp_table.focus_row_by_keyboard(bravo)

      wp_table.press_menu_key
      context_menu.expect_open
      expect(page).to have_selector(:menuitem, focused: true)
      wp_table.press_keys(:escape)
      context_menu.expect_closed
      wp_table.expect_focus_on_row(bravo)

      wp_table.press_keys(%i[shift alt f10])
      context_menu.expect_open
      expect(page).to have_selector(:menuitem, focused: true)
      wp_table.press_keys(:escape)
      context_menu.expect_closed
      wp_table.expect_focus_on_row(bravo)
    end

    it "keeps the selection and the header focus when sorting from the column menu" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(bravo, charlie)

      wp_table.press_keys(:right, :right, :up, :up, :up)
      wp_table.expect_focus_on_column_header("Subject")
      wp_table.press_keys(:enter)
      within "#column-context-menu" do
        click_on "Sort descending"
      end

      wp_table.expect_work_package_order(echo, delta, charlie, bravo, alpha)
      expect_selection(bravo, charlie)
      wp_table.expect_focus_on_column_header("Subject")
    end

    it "follows a column moved from the column menu with focus" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(:right, :right, :up, :up)
      wp_table.expect_focus_on_column_header("Subject")
      wp_table.press_keys(:enter)
      within "#column-context-menu" do
        click_on "Move column left"
      end

      wp_table.expect_focus_on_column_header("Subject")
      wp_table.press_keys(:right)
      wp_table.expect_focus_on_column_header("ID")
    end

    it "returns focus to the previous column after hiding a column from the column menu" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(:right, :right, :up, :up)
      wp_table.expect_focus_on_column_header("Subject")
      wp_table.press_keys(:enter)
      within "#column-context-menu" do
        click_on "Hide column"
      end

      wp_table.expect_focus_on_column_header("ID")
      wp_table.press_keys(:down)
      wp_table.expect_focus_on_cell(alpha, :id)
    end

    it "returns focus to the originating row when the menu is closed with Escape" do
      wp_table.focus_row_by_keyboard(delta)

      wp_table.press_keys(%i[shift f10])
      context_menu.expect_open
      expect(page).to have_selector(:menuitem, focused: true)
      wp_table.press_keys(:escape)

      context_menu.expect_closed
      wp_table.expect_focus_on_row(delta)
      expect_selection(delta)
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:111
    it "mixes pointer and keyboard gestures on one selection and anchor" do
      modifier = BrowserPlatform.multi_select_modifier(page)
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], %i[shift down], %i[shift down])
      expect_selection(alpha, bravo, charlie)

      wp_table.row(echo).click(:shift)
      expect_selection(*listed)

      wp_table.row(bravo).click(modifier)
      expect_selection(alpha, charlie, delta, echo)
    end

    it "announces the page scope on Select All, and when the selection is cleared" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(select_all_chord)
      live_region.expect_announcement("All 5 work packages on this page selected.")

      wp_table.press_keys(:escape)
      live_region.expect_announcement("Selection cleared.")
    end

    it "announces each range change from a fixed anchor" do
      wp_table.focus_row_by_keyboard(charlie)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(charlie, delta)
      live_region.expect_announcement("2 work packages selected.")

      wp_table.press_keys(%i[shift down])
      expect_selection(charlie, delta, echo)
      live_region.expect_announcement("3 work packages selected.")

      wp_table.press_keys(:up, :up, :up, :up)
      wp_table.expect_focus_on_row(alpha)
      wp_table.press_keys(%i[shift down])
      expect_selection(bravo, charlie)
      live_region.expect_announcement("2 work packages selected.")
    end

    it "announces the remaining selection when a filter drops a selected work package" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(alpha, bravo)
      live_region.expect_announcement("2 work packages selected.")

      filters.open
      filters.add_filter_by("Subject", "doesn't contain", ["Bravo"])
      wp_table.expect_work_package_order(alpha, charlie, delta, echo)

      expect(wp_table.treegrid).to have_selector(:row, alpha.subject, aria: { selected: true })
      expect(wp_table.treegrid).to have_selector(:row, aria: { selected: true }, count: 1)
      live_region.expect_announcement("1 work package selected.")
    end

    it "announces the remaining selection when a plain click collapses a batch" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], %i[shift down], %i[shift down])
      expect_selection(alpha, bravo, charlie)
      live_region.expect_announcement("3 work packages selected.")

      wp_table.row(delta).click
      expect_selection(delta)
      live_region.expect_announcement("1 work package selected.")
    end

    it "announces a same-count replacement afresh" do
      wp_table.focus_row_by_keyboard(charlie)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(charlie, delta)
      live_region.expect_announcement("2 work packages selected.")

      wp_table.press_keys(:up)
      wp_table.expect_focus_on_row(charlie)
      expect_selection(charlie, delta)

      wp_table.press_keys(%i[shift up])
      expect_selection(bravo, charlie)
      # The live region repeats an identical message with a trailing no-break space.
      live_region.expect_announcement(/\A2 work packages selected\.[ \u00A0]\z/)
    end

    # Backlogs counterpart: modules/backlogs/spec/features/work_packages/batch_selection_spec.rb:202
    # Divergence: Enter is click-like in the table and re-anchors, Backlogs passes it through.
    it "selects only the focused row on Enter and re-anchors there" do
      wp_table.focus_row_by_keyboard(bravo)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(bravo, charlie)

      wp_table.press_keys(:enter)
      expect_selection(charlie)

      wp_table.press_keys(%i[shift down])
      expect_selection(charlie, delta)
    end
  end

  context "in a grouped table" do
    let(:one) { create(:category, project:, name: "Group one") }
    let(:two) { create(:category, project:, name: "Group two") }
    let!(:alpha) { create(:work_package, project:, category: one, subject: "Alpha task") }
    let!(:bravo) { create(:work_package, project:, category: one, subject: "Bravo task") }
    let!(:charlie) { create(:work_package, project:, category: two, subject: "Charlie task") }
    let!(:delta) { create(:work_package, project:, category: two, subject: "Delta task") }
    let(:listed) { [alpha, bravo, charlie, delta] }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject estimated_hours],
                     sort_criteria: [%w[subject asc]], group_by: "category",
                     show_hierarchies: false, display_sums: true)
    end

    before do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(*listed)
      wp_table.expect_inline_create_button
    end

    it "passes Shift+ArrowDown through sums rows and group headers without changing the range" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(alpha, bravo)

      wp_table.press_keys(%i[shift down])
      expect(wp_table.treegrid).to have_selector(:row, /\bSum\b/, focused: true)
      expect_selection(alpha, bravo)

      wp_table.press_keys(%i[shift down])
      expect(wp_table.treegrid).to have_selector(:row, "Group two", focused: true)
      expect_selection(alpha, bravo)

      wp_table.press_keys(%i[shift down])
      expect_selection(alpha, bravo, charlie)
      wp_table.expect_focus_on_row(charlie)
    end

    it "does not open a context menu from a group header" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(:up)
      expect(wp_table.treegrid).to have_selector(:row, "Group one", focused: true)

      wp_table.press_keys(%i[shift f10], :down)

      wp_table.expect_focus_on_row(alpha)
      expect(page).to have_no_selector(:menu)
    end

    it "does not consume Shift+Space on a group header and leaves the selection alone" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], :up)
      expect(wp_table.treegrid).to have_selector(:row, "Group one", focused: true)

      wp_table.press_keys(%i[shift space])

      expect_selection(alpha)
    end

    it "selects only work packages with Select All from a group header, without anchoring" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(:up)
      expect(wp_table.treegrid).to have_selector(:row, "Group one", focused: true)

      wp_table.press_keys(select_all_chord)
      expect_selection(*listed)
      live_region.expect_announcement("All 4 work packages on this page selected.")

      wp_table.press_keys(%i[shift down])
      expect(wp_table.treegrid).to have_selector(:row, "Alpha task", focused: true)
      expect_selection(alpha)
    end

    it "leaves the selection alone on Shift+Space on a sums row" do
      wp_table.focus_row_by_keyboard(alpha)
      wp_table.press_keys(%i[shift space], %i[shift down])
      expect_selection(alpha, bravo)

      wp_table.press_keys(%i[shift down])
      expect(wp_table.treegrid).to have_selector(:row, /\bSum\b/, focused: true)
      wp_table.press_keys(%i[shift space])

      expect_selection(alpha, bravo)
    end
  end

  context "in an expanded hierarchy" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %i[view_work_packages edit_work_packages add_work_packages delete_work_packages manage_subtasks]
             })
    end
    let!(:parent) { create(:work_package, project:, subject: "Alpha parent") }
    let!(:child) { create(:work_package, project:, parent:, subject: "Bravo child") }
    let!(:sibling) { create(:work_package, project:, subject: "Charlie sibling") }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject],
                     sort_criteria: [%w[subject asc]], show_hierarchies: true)
    end

    before do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(parent, child, sibling)
    end

    it "keeps focus on the work package after a menu action re-renders the table" do
      wp_table.focus_row_by_keyboard(child)
      expect(wp_table.treegrid).to have_selector(:row, "Bravo child", aria: { level: 2 })

      wp_table.press_keys(%i[shift f10])
      context_menu.expect_open
      context_menu.choose("Outdent hierarchy")

      expect(wp_table.treegrid).to have_selector(:row, "Bravo child", aria: { level: 1 })
      wp_table.expect_focus_on_row(child)
    end
  end

  context "in a hierarchy with a collapsed parent" do
    let!(:parent) { create(:work_package, project:, subject: "Alpha parent") }
    let!(:child) { create(:work_package, project:, parent:, subject: "Bravo child") }
    let!(:sibling) { create(:work_package, project:, subject: "Charlie sibling") }
    let!(:other) { create(:work_package, project:, subject: "Delta other") }
    let(:listed) { [parent, child, sibling, other] }
    let!(:query) do
      create(:query, user:, project:, column_names: %w[id subject],
                     sort_criteria: [%w[subject asc]], show_hierarchies: true)
    end

    def expect_selection(*selected)
      listed.each do |work_package|
        expect(wp_table.treegrid)
          .to have_css("tr[data-work-package-id='#{work_package.id}']" \
                       "[aria-selected='#{selected.include?(work_package)}']",
                       visible: :all)
      end
    end

    before do
      wp_table.visit_query(query)
      wp_table.expect_work_package_order(parent, child, sibling, other)
      collapse_parent
    end

    def collapse_parent
      find(:role, "button", accessible_name: /\AHierarchy level 1, expanded\./).click
      expect(wp_table.treegrid).to have_no_css("tr[data-work-package-id='#{child.id}']")
    end

    it "includes collapsed children in a Shift+ArrowDown range" do
      wp_table.focus_row_by_keyboard(parent)
      wp_table.press_keys(%i[shift space])
      expect_selection(parent)

      wp_table.press_keys(%i[shift down])

      wp_table.expect_focus_on_row(sibling)
      expect_selection(parent, child, sibling)
    end

    it "includes collapsed children in Select All" do
      wp_table.focus_row_by_keyboard(sibling)
      wp_table.press_keys(select_all_chord)

      expect_selection(*listed)
      live_region.expect_announcement("All 4 work packages on this page selected.")
    end
  end
end
