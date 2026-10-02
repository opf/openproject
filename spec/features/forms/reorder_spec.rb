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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Reordering a form on its page", :js, :selenium do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:work_package) { create(:work_package, project:, type:) }
  shared_let(:form) { create(:form_configuration, name: "Reordered form") }
  shared_let(:people) { create(:form_configuration_group, form_configuration: form, label: "People") }
  shared_let(:details) { create(:form_configuration_group, form_configuration: form, label: "Details") }
  shared_let(:spare) { create(:form_configuration_group, form_configuration: form, label: "Spare") }

  before_all do
    { people => %w[assignee responsible], details => %w[priority category date] }.each do |group, keys|
      keys.each.with_index(1) do |key, position|
        create(:form_configuration_attribute, form_configuration: form, group:, position:, attribute_key: key)
      end
    end
    type.default_variant.update!(form_configuration: form)
  end

  let(:editor) { Pages::Forms::Edit.new(form) }

  current_user { admin }

  def moving(wait: Capybara.default_max_wait_time, &) = wait_for_turbo_stream(wait:, &)

  def expect_work_package_groups_in_order(first, second)
    page.document.synchronize do
      found = page.all(:heading).map { it.text.downcase }
      positions = [first, second].map { found.index(it.downcase) }
      next if positions.all? && positions.first < positions.last

      raise Capybara::ExpectationNotMet, "Expected #{first} above #{second}, got #{found}"
    end
  end

  context "with an Enterprise token", with_ee: %i[edit_attribute_groups] do
    before do
      editor.visit!
      editor.expect_group_order("People", "Details", "Spare")
    end

    it "reorders groups by dragging, twice, and keeps the order" do
      moving { editor.drag_group("People", below: "Details") }
      editor.expect_group_order("Details", "People", "Spare")

      moving { editor.drag_group("People", below: "Spare") }
      editor.expect_group_order("Details", "Spare", "People")

      page.refresh
      editor.expect_group_order("Details", "Spare", "People")

      work_package_page = Pages::FullWorkPackage.new(work_package)
      work_package_page.visit!
      work_package_page.ensure_page_loaded
      expect_work_package_groups_in_order("Details", "People")
    end

    it "moves attributes between groups, into an empty group and through the inactive list" do
      moving { editor.drag_attribute(:priority, to_group: "People") }
      editor.expect_attributes("Details", :category, :date)

      moving { editor.drag_attribute(:category, to_group: "Spare") }
      editor.expect_attributes("Spare", :category)

      moving { editor.drag_attribute(:date, to_inactive: true) }
      editor.expect_inactive(:date)
      editor.expect_attributes("Details")

      moving { editor.drag_attribute(:date, to_group: "Details") }
      editor.expect_attributes("Details", :date)

      page.refresh
      editor.expect_attributes("Spare", :category)
      editor.expect_attributes("Details", :date)
    end

    it "moves groups and rows with the menu and offers only the directions that apply" do
      editor.expect_group_moves("People", offered: ["Move down", "Move to bottom"], absent: ["Move up", "Move to top"])
      editor.expect_attribute_moves(:priority, offered: ["Move down", "Move to bottom"], absent: ["Move up", "Move to top"])
      editor.expect_attribute_moves(:date, offered: ["Move up", "Move to top"], absent: ["Move down", "Move to bottom"])

      moving { editor.move_group("People", "Move to bottom") }
      editor.expect_group_order("Details", "Spare", "People")

      moving { editor.move_attribute(:date, "Move up") }
      editor.expect_attributes("Details", :priority, :date, :category)
      editor.expect_group_order("Details", "Spare", "People")

      page.refresh
      editor.expect_group_order("Details", "Spare", "People")
      editor.expect_attributes("Details", :priority, :date, :category)
    end

    it "shows a section's empty state only while it has no attributes" do
      editor.expect_empty_state("Spare")

      moving { editor.drag_attribute(:category, to_group: "Spare") }
      editor.expect_no_empty_state("Spare")
      editor.expect_attributes("Spare", :category)

      moving { editor.drag_attribute(:category, to_group: "Details") }
      editor.expect_empty_state("Spare")
    end

    it "reorders rows within a group by dragging" do
      moving { editor.drag_attribute_beside(:date, above: :priority) }
      editor.expect_attributes("Details", :date, :priority, :category)

      moving { editor.drag_attribute_beside(:priority, below: :category) }
      editor.expect_attributes("Details", :date, :category, :priority)

      page.refresh
      editor.expect_attributes("Details", :date, :category, :priority)
    end

    it "asks before a menu move discards an open group editor" do
      editor.start_renaming("People")

      dismiss_confirm { editor.move_group("Spare", "Move to top") }
      editor.expect_group_order("People", "Details", "Spare")
      expect(page).to have_field(with: "People")

      moving { accept_confirm { editor.move_group("Spare", "Move to top") } }
      editor.expect_group_order("Spare", "People", "Details")
      expect(page).to have_no_field(with: "People")
    end

    it "asks before a drag discards an open group editor" do
      editor.start_renaming("People")

      dismiss_confirm { editor.drag_group("Details", below: "Spare") }

      editor.expect_group_order("People", "Details", "Spare")
      expect(page).to have_field(with: "People")

      page.refresh
      editor.expect_group_order("People", "Details", "Spare")
    end

    it "moves a dragged group once an open group editor may be discarded" do
      editor.start_renaming("People")

      moving { accept_confirm { editor.drag_group("Details", below: "Spare") } }

      editor.expect_group_order("People", "Spare", "Details")
      expect(page).to have_no_field(with: "People")

      page.refresh
      editor.expect_group_order("People", "Spare", "Details")
    end

    it "keeps the inactive filter applied after a move" do
      moving { editor.drag_attribute(:date, to_inactive: true) }
      moving { editor.drag_attribute(:category, to_inactive: true) }
      editor.filter_inactive("Date")
      editor.expect_hidden_in_inactive(:category)

      moving { editor.drag_attribute(:date, to_group: "People") }

      editor.expect_attributes("People", :assignee, :date, :responsible)
      editor.expect_hidden_in_inactive(:category)
    end

    it "offers a custom field created after the form was last saved" do
      custom_field = create(:wp_custom_field, name: "Late field")
      page.refresh
      editor.expect_inactive(custom_field.attribute_name)

      moving { editor.drag_attribute(custom_field.attribute_name, to_group: "Spare") }

      editor.expect_attributes("Spare", custom_field.attribute_name)

      page.refresh
      editor.expect_attributes("Spare", custom_field.attribute_name)
    end
  end

  context "with more groups than fit the window", with_ee: %i[edit_attribute_groups] do
    include_context "with mobile screen size", 1280, 800

    before do
      6.times { create(:form_configuration_group, form_configuration: form, label: "Filler #{it}") }
      editor.visit!
    end

    it "scrolls the group list while dragging toward its lower edge" do
      editor.expect_group_out_of_view("Filler 5")

      moving(wait: 10) { editor.drag_group_to_list_end("People") }

      editor.expect_group_in_view("Filler 5")
      editor.expect_group_order("Details", "Spare", *Array.new(6) { "Filler #{it}" }, "People")
    end
  end

  context "with a form created from scratch", with_ee: %i[edit_attribute_groups] do
    let(:scratch) { create(:form_configuration, name: "From scratch") }
    let(:editor) { Pages::Forms::Edit.new(scratch) }

    it "shows the default groups and lets them be reordered" do
      editor.visit!
      editor.expect_groups_starting_with("People", "Estimates and progress")

      moving { editor.drag_group("People", below: "Estimates and progress") }
      editor.expect_groups_starting_with("Estimates and progress", "People")

      page.refresh
      editor.expect_groups_starting_with("Estimates and progress", "People")
    end
  end

  context "without an Enterprise token" do
    it "still reorders groups and rows" do
      editor.visit!
      editor.expect_group_order("People", "Details", "Spare")

      moving { editor.drag_group("People", below: "Details") }
      editor.expect_group_order("Details", "People", "Spare")

      moving { editor.move_attribute(:priority, "Move down") }
      editor.expect_attributes("Details", :category, :priority, :date)

      page.refresh
      editor.expect_group_order("Details", "People", "Spare")
      editor.expect_attributes("Details", :category, :priority, :date)
    end
  end
end
