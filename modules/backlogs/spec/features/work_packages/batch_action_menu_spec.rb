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
require_relative "../../support/pages/backlog"

RSpec.describe "Backlogs batch action menus", :js, :selenium, :settings_reset do
  entry_points = %i[more right_click context_menu_key shift_f10]
  let(:singular_actions) { ["Open details view", "Open fullscreen view", "Copy link to clipboard", "Copy work package ID"] }
  let(:no_batch_actions) { "No actions available for the selected work packages." }

  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:permissions) { %i[view_sprints manage_sprint_items view_work_packages edit_work_packages] }
  let(:role) { create(:project_role, permissions:) }
  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  def create_stories(count: 4, **attributes)
    Array.new(count) do |index|
      create(:work_package, project:, type:, position: index + 1, **attributes)
    end
  end

  context "with a sprint and another sprint to move to" do
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:destination_sprint) { create(:sprint, project:, name: "Destination") }
    let!(:stories) { create_stories(sprint:) }

    before do
      backlogs_page.visit!
    end

    entry_points.each do |via|
      context "via #{via.to_s.tr('_', ' ')}" do
        it "opens the batch menu on a selected card and keeps the selection", :aggregate_failures do
          backlogs_page.select_cards(stories[1], stories[0])

          menu = backlogs_page.open_card_menu(stories[1], via:)

          expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
          backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
          expect(menu).to have_selector(:menuitem, text: "Move to sprint")
          expect(menu).to have_selector(:menuitem, text: "Move to position")
          singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }

          backlogs_page.dismiss_card_menu(stories[1], via:)

          backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
          backlogs_page.expect_work_package_menu_button_named(stories[1], "Work package actions")
        end

        it "replaces the selection with an unselected card and opens its own menu", :aggregate_failures do
          backlogs_page.select_cards(stories[0], stories[1])

          menu = backlogs_page.open_card_menu(stories[2], via:)

          backlogs_page.expect_selected_cards_in_order(stories[2])
          expect(page).to have_selector(:menu, accessible_name: "Work package actions")
          singular_actions.each { |label| expect(menu).to have_selector(:menuitem, text: label) }
          expect(menu).to have_selector(:menuitem, text: "Move to sprint")
          expect(menu).to have_selector(:menuitem, text: "Move to position")

          backlogs_page.dismiss_card_menu(stories[2], via:)

          backlogs_page.expect_selected_cards_in_order(stories[2])
        end
      end
    end

    it "scans the batch menu, its batch name and the singular menu clean" do
      backlogs_page.select_cards(stories[1], stories[2])
      backlogs_page.open_card_menu(stories[1], via: :more)
      backlogs_page.expect_work_package_menu_button_named(stories[1], "Actions for 2 selected work packages")
      backlogs_page.expect_open_card_menu_axe_clean(stories[1])
      backlogs_page.dismiss_card_menu(stories[1], via: :more)

      backlogs_page.open_card_menu(stories[3], via: :more)
      backlogs_page.expect_open_card_menu_axe_clean(stories[3])
    end

    it "restores card focus when a contextual batch menu is light-dismissed" do
      backlogs_page.select_cards(stories[0], stories[1])
      backlogs_page.open_card_menu(stories[1], via: :right_click)

      backlogs_page.light_dismiss_card_menu(stories[1])

      backlogs_page.expect_work_package_card_focused(stories[1])
      backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
    end

    it "passes the ordered batch to a destination dialog and a positional move" do
      backlogs_page.select_contiguous_cards(stories[1], stories[2])

      backlogs_page.activate_card_menu_action(stories[2], "Move to sprint", via: :context_menu_key)
      backlogs_page.expect_destination_dialog("Move to sprint", work_packages: [stories[1], stories[2]])
      backlogs_page.cancel_destination_dialog("Move to sprint")

      backlogs_page.activate_card_menu_action(stories[1], "Move down", via: :shift_f10)

      moved_order = [stories[0], stories[3], stories[1], stories[2]]
      backlogs_page.expect_sprint_items_in_order(sprint, items: moved_order)

      backlogs_page.visit!
      backlogs_page.expect_sprint_items_in_order(sprint, items: moved_order)
    end

    it "keeps destination actions when the whole list has no valid position", :aggregate_failures do
      backlogs_page.select_contiguous_cards(stories.first, stories.last)

      menu = backlogs_page.open_card_menu(stories[0], via: :more)

      expect(page).to have_selector(:menu, accessible_name: "Actions for 4 selected work packages")
      expect(menu).to have_selector(:menuitem, text: "Move to sprint")
      expect(menu).to have_no_selector(:menuitem, text: "Move to position")
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }
    end
  end

  context "with inbox cards and nowhere else to move them" do
    let!(:stories) { create_stories(count: 3) }

    before do
      backlogs_page.visit!
    end

    it "offers only Move to position to a contiguous batch", :aggregate_failures do
      backlogs_page.select_contiguous_cards(stories[0], stories[1])

      menu = backlogs_page.open_card_menu(stories[0], via: :right_click)

      expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
      expect(menu).to have_selector(:menuitem, text: "Move to position")
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }
    end

    it "explains a batch that cannot move by position", :aggregate_failures do
      backlogs_page.select_contiguous_cards(stories.first, stories.last)

      menu = backlogs_page.open_card_menu(stories[2], via: :more)

      expect(page).to have_selector(:menu, accessible_name: "Actions for 3 selected work packages")
      expect(menu).to have_selector(:menuitem, text: no_batch_actions, disabled: true)
      expect(menu).to have_no_text("Move to position")
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }
      backlogs_page.expect_work_package_menu_button_named(stories[2], "Actions for 3 selected work packages")
      backlogs_page.expect_selected_cards_in_order(*stories)
    end

    it "keeps the menu open on the explanation when opened from the keyboard", :aggregate_failures do
      backlogs_page.select_contiguous_cards(stories.first, stories.last)

      menu = backlogs_page.open_card_menu(stories[0], via: :shift_f10)

      expect(menu).to have_selector(:menuitem, text: no_batch_actions, disabled: true, focused: true)
      expect(page).to have_selector(:menu, accessible_name: "Actions for 3 selected work packages")
    end
  end

  context "with read-only cards in two sprints", with_ee: %i[readonly_work_packages] do
    let(:readonly_status) { create(:status, :readonly) }
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:other_sprint) { create(:sprint, project:, name: "Other sprint") }
    let!(:story) { create(:work_package, project:, type:, status: readonly_status, sprint:) }
    let!(:other_story) { create(:work_package, project:, type:, status: readonly_status, sprint: other_sprint) }

    before do
      backlogs_page.visit!
    end

    it "explains a batch that no action applies to", :aggregate_failures do
      backlogs_page.select_cards(story, other_story)

      menu = backlogs_page.open_card_menu(story, via: :more)

      expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
      expect(menu).to have_selector(:menuitem, text: no_batch_actions, disabled: true)
      expect(menu).to have_no_text("Move to position")
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }
    end
  end

  context "with more cards selected than one batch may move" do
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:destination_sprint) { create(:sprint, project:, name: "Destination") }
    let!(:stories) { create_stories(sprint:) }

    before do
      stub_const("Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE", 2)
      backlogs_page.visit!
    end

    it "disables the batch actions and explains why once", :aggregate_failures do
      backlogs_page.select_contiguous_cards(stories[0], stories[2])

      menu = backlogs_page.open_card_menu(stories[1], via: :more)

      expect(page).to have_selector(:menu, accessible_name: "Actions for 3 selected work packages")
      expect(menu).to have_selector(:menuitem,
                                    text: "Cannot move 3 work packages at once. Select no more than 2.",
                                    disabled: true,
                                    count: 1)
      expect(menu).to have_selector(:menuitem, text: "Move to sprint", disabled: true)
      expect(menu).to have_selector(:menuitem, text: "Move to backlog inbox", disabled: true)
      expect(menu).to have_selector(:menuitem, text: "Move to position", disabled: true)
      expect(menu).to have_no_selector(:menuitem, text: "Move to sprint")
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }

      backlogs_page.expect_open_card_menu_axe_clean(stories[1])
    end

    it "does nothing when a disabled action is chosen" do
      backlogs_page.select_contiguous_cards(stories[0], stories[2])

      menu = backlogs_page.open_card_menu(stories[1], via: :more)
      menu.find(:menuitem, text: "Move to sprint", disabled: true).click
      menu.find(:menuitem, text: "Move to position", disabled: true).click

      backlogs_page.expect_no_destination_dialog
      expect(page).to have_no_selector(:menuitem, text: "Move to top", disabled: true)
      backlogs_page.expect_selected_cards_in_order(stories[0], stories[1], stories[2])
      backlogs_page.expect_sprint_items_in_order(sprint, items: stories)
    end
  end

  context "with the real batch boundary and no other destination" do
    let!(:stories) { create_stories(count: 51) }

    it "offers position at 50 and one cap explanation at 51", :aggregate_failures do
      backlogs_page.visit!
      backlogs_page.select_contiguous_cards(stories.first, stories[49])

      menu = backlogs_page.open_card_menu(stories[49], via: :more)
      expect(page).to have_selector(:menu, accessible_name: "Actions for 50 selected work packages")
      expect(menu).to have_selector(:menuitem, text: "Move to position")
      expect(menu).to have_no_text("Cannot move")
      backlogs_page.dismiss_card_menu(stories[49], via: :more)

      backlogs_page.extend_selection_to(stories.last)
      menu = backlogs_page.open_card_menu(stories.last, via: :more)
      expect(page).to have_selector(:menu, accessible_name: "Actions for 51 selected work packages")
      expect(menu).to have_selector(:menuitem,
                                    text: "Cannot move 51 work packages at once. Select no more than 50.",
                                    disabled: true,
                                    count: 1)
      expect(menu).to have_selector(:menuitem, text: "Move to position", disabled: true)
      expect(menu).to have_no_selector(:menuitem, text: "Move to sprint", disabled: true)
      expect(menu).to have_no_selector(:menuitem, text: "Move to backlog bucket", disabled: true)
      singular_actions.each { |label| expect(menu).to have_no_selector(:menuitem, text: label) }
      backlogs_page.expect_open_card_menu_axe_clean(stories.last)

      requests_before = move_request_count
      menu.find(:menuitem, text: "Move to position", disabled: true).click
      expect(page).to have_no_selector(:menuitem, text: "Move to top")
      backlogs_page.expect_selected_cards_in_order(*stories)
      backlogs_page.expect_inbox_items_in_order(items: stories)
      expect(move_request_count).to eq(requests_before)
    end
  end

  def move_request_count
    page.evaluate_script(<<~JS)
      performance.getEntriesByType("resource")
        .filter((entry) => /\\/backlogs\\/work_packages(\\/\\d+)?\\/move\\b/.test(entry.name)).length
    JS
  end

  context "when every card is fixed" do
    let(:permissions) { %i[view_sprints view_work_packages] }
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:stories) { create_stories(count: 2, sprint:) }

    before do
      backlogs_page.visit!
    end

    entry_points.each do |via|
      it "opens the card's own menu via #{via.to_s.tr('_', ' ')} without selecting it", :aggregate_failures do
        menu = backlogs_page.open_card_menu(stories[0], via:)

        expect(page).to have_selector(:menu, accessible_name: "Work package actions")
        expect(menu).to have_selector(:menuitem, text: "Open details view")
        expect(menu).to have_no_selector(:menuitem, text: "Move to position")
        backlogs_page.expect_no_selected_cards
      end
    end
  end
end
