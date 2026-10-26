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

  it "enters the actions cell and returns a keyboard menu to that cell" do
    wp_table.focus_cell_by_keyboard(sibling, :subject)
    wp_table.press_keys(:end)
    actions = wp_table.row(sibling).find("td.__internal-contextMenu")
    expect(actions).to match_selector(":focus")
    wp_table.press_keys(:enter)
    wp_table.expect_focus_on_control(sibling, "Open details view")
    wp_table.press_keys(:tab)
    wp_table.expect_focus_on_control(sibling, "Open context menu")
    wp_table.press_keys(%i[shift f10])
    menu = Components::WorkPackages::ContextMenu.new
    menu.expect_open
    expect(page).to have_css("#work-package-context-menu", count: 1)

    wp_table.press_keys(:escape)
    menu.expect_closed
    expect(actions).to match_selector(":focus")
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
    expect(wp_table.row(parent)).to have_button(accessible_name: /Hierarchy level 1, expanded/, focused: true)
  end

  %i[keyboard pointer].product(%i[cell toolbar]).each do |entry, destination|
    it "preserves newer #{destination} focus after saving a #{entry}-opened editor" do
      submitted = Concurrent::Event.new
      release = Concurrent::Event.new
      allow(WorkPackages::UpdateService).to receive(:new).and_wrap_original do |original, **arguments|
        service = original.call(**arguments)
        allow(service).to receive(:call).and_wrap_original do |update, *args, **kwargs|
          submitted.set
          raise "Timed out waiting to release the update" unless release.wait(10)

          update.call(*args, **kwargs)
        end
        service
      end

      field = wp_table.edit_field(sibling, :subject)
      if entry == :keyboard
        wp_table.focus_cell_by_keyboard(sibling, :subject)
        wp_table.press_keys(:enter)
      else
        field.activate!
      end
      field.input_element.set("Saved draft")
      wp_table.press_keys(:enter)
      expect(submitted.wait(10)).to be(true)
      if destination == :cell
        wp_table.focus_cell_by_keyboard(parent, :subject)
      else
        wp_table.focus_row_by_keyboard(parent)
        wp_table.press_keys(%i[shift tab])
        expect(page).to have_css("#content .toolbar-items :focus")
      end
      focused = page.find(":focus")
      release.set

      wp_table.expect_toast(message: "Successful update.")
      field.expect_inactive!
      wp_table.expect_work_package_subject("Saved draft")
      expect(focused).to match_selector(":focus")
    ensure
      release&.set
    end
  end

  it "returns date save to the keyboard-opened cell" do
    query = create(:query, user:, project:, column_names: %w[id subject start_date due_date])
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(sibling)
    wp_table.focus_cell_by_keyboard(sibling, :startDate)
    wp_table.press_keys(:enter)
    date = wp_table.edit_field(sibling, :startDate)
    date.datepicker.expect_visible
    date.set_value("2026-10-26")
    date.save!
    wp_table.expect_toast(message: "Successful update.")
    wp_table.expect_focus_on_cell(sibling, :startDate)
  end

  it "returns date cancel to the keyboard-opened cell" do
    query = create(:query, user:, project:, column_names: %w[id subject start_date due_date])
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(sibling)
    wp_table.focus_cell_by_keyboard(sibling, :dueDate)
    wp_table.press_keys(:enter)
    date = wp_table.edit_field(sibling, :dueDate)
    date.datepicker.expect_visible
    date.cancel_by_click
    wp_table.expect_focus_on_cell(sibling, :dueDate)
  end

  it "keeps Tab inside an open date editor" do
    query = create(:query, user:, project:, column_names: %w[id subject start_date due_date])
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(sibling)
    wp_table.focus_cell_by_keyboard(sibling, :startDate)
    wp_table.press_keys(:enter)
    wp_table.edit_field(sibling, :startDate).datepicker.expect_visible

    20.times { wp_table.press_keys(:tab) }
    expect(page).to have_css('[role="dialog"]:focus-within')
    20.times { wp_table.press_keys(%i[shift tab]) }
    expect(page).to have_css('[role="dialog"]:focus-within')
  end

  it "returns to the cell when a table reload retires an open date editor" do
    query = create(:query, user:, project:, column_names: %w[id subject start_date due_date])
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(sibling)
    hold_requests("/api/v3/queries/#{query.id}") do |held|
      wp_table.focus_cell_by_keyboard(sibling, :startDate)
      wp_table.press_keys(:enter)
      start_date = wp_table.edit_field(sibling, :startDate)
      start_date.datepicker.expect_visible
      start_date.set_value("2026-10-26")
      start_date.save!
      wp_table.expect_toast(message: "Successful update.")
      reload = held.pop(timeout: 10)
      expect(reload).not_to be_nil
      wp_table.focus_cell_by_keyboard(sibling, :dueDate)
      wp_table.press_keys(:enter)
      due_date = wp_table.edit_field(sibling, :dueDate)
      due_date.datepicker.expect_visible
      reload.continue

      expect(page).to have_no_css(due_date.datepicker.context_selector)
      wp_table.expect_focus_on_cell(sibling, :dueDate)
    end
  end

  context "with a milestone sibling" do
    let(:milestone_type) { create(:type_milestone) }
    let(:project) { create(:project, types: [create(:type), milestone_type]) }
    let!(:sibling) { create(:work_package, project:, type: milestone_type, subject: "Bravo sibling") }

    it "returns milestone date cancel and save to the keyboard-opened cell" do
      query = create(:query, user:, project:, column_names: %w[id subject start_date])
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(sibling)
      wp_table.focus_cell_by_keyboard(sibling, :startDate)
      wp_table.press_keys(:enter)
      date = wp_table.edit_field(sibling, :startDate)
      date.datepicker.expect_visible
      date.cancel_by_click
      wp_table.expect_focus_on_cell(sibling, :startDate)

      wp_table.press_keys(:enter)
      date.datepicker.expect_visible
      date.set_value("2026-10-26")
      date.save!
      wp_table.expect_toast(message: "Successful update.")
      wp_table.expect_focus_on_cell(sibling, :startDate)
    end
  end

  context "with a relation query group in the split view" do
    let(:type) { create(:type_with_relation_query_group, relation_filter: :parent) }
    let(:project) { create(:project, types: [type]) }
    let!(:parent) { create(:work_package, project:, type:, subject: "Charlie parent") }
    let!(:child) { create(:work_package, project:, type:, parent:, subject: "Alpha child") }
    let!(:sibling) { create(:work_package, project:, type:, subject: "Bravo sibling") }

    it "keeps focus in the embedded table when a pending grid save completes" do
      submitted = Concurrent::Event.new
      release = Concurrent::Event.new
      allow(WorkPackages::UpdateService).to receive(:new).and_wrap_original do |original, **arguments|
        service = original.call(**arguments)
        if arguments[:model] == sibling
          allow(service).to receive(:call).and_wrap_original do |update, *args, **kwargs|
            submitted.set
            raise "Timed out waiting to release the update" unless release.wait(10)

            update.call(*args, **kwargs)
          end
        end
        service
      end

      split = Pages::PrimerizedSplitWorkPackage.new(parent, project)
      split.visit!
      wp_table.expect_work_package_listed(parent, child, sibling)
      embedded = Pages::EmbeddedWorkPackagesTable.new(find("wp-single-view .work-packages-embedded-view--container"))
      embedded.expect_work_package_listed(child)

      field = wp_table.edit_field(sibling, :subject)
      wp_table.focus_cell_by_keyboard(sibling, :subject)
      wp_table.press_keys(:enter)
      field.input_element.set("Saved draft")
      wp_table.press_keys(:enter)
      expect(submitted.wait(10)).to be(true)

      embedded_field = embedded.edit_field(child, :subject)
      within(embedded.table_container) do
        embedded_field.display_element.click
        expect(embedded_field.input_element).to match_selector(":focus")
      end
      release.set

      wp_table.expect_toast(message: "Successful update.")
      field.expect_inactive!
      wp_table.expect_work_package_subject("Saved draft")
      within(embedded.table_container) do
        expect(embedded_field.input_element).to match_selector(":focus")
      end
    ensure
      release&.set
    end
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

  it "parks and re-engages an editor across a backward table exit" do
    wp_table.focus_cell_by_keyboard(sibling, :subject)
    wp_table.press_keys(:enter)
    field = wp_table.edit_field(sibling, :subject)
    field.input_element.set("Parked draft")

    wp_table.press_keys(%i[shift tab])
    wp_table.expect_focus_on_cell(sibling, :subject)

    wp_table.press_keys(:enter)
    expect(page).to have_focus_on("##{field.input_element[:id]}")
    expect(field.input_element.value).to eq("Parked draft")
  end
end
