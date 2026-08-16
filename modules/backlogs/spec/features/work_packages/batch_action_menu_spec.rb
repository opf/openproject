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
require_relative "../../support/pages/backlog"

RSpec.describe "Backlogs batch action menus", :js, :selenium, :settings_reset do
  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:permissions) { %i[view_sprints manage_sprint_items view_work_packages edit_work_packages] }
  let(:role) { create(:project_role, permissions:) }
  let!(:sprint) { create(:sprint, project:, name: "Sprint") }
  let!(:stories) do
    Array.new(4) do |index|
      create(:work_package, project:, type:, sprint:, position: index + 1)
    end
  end
  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  before do
    backlogs_page.visit!
  end

  %i[more right_click context_menu_key shift_f10].each do |entry_point|
    context "via #{entry_point.to_s.tr('_', ' ')}" do
      it "preserves a selected batch across its menu lifecycle" do
        backlogs_page.select_cards(stories[1], stories[0])

        menu = backlogs_page.open_card_menu(stories[1], via: entry_point)

        backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
        expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"), focused: true)
        backlogs_page.expect_card_menu_anchor(stories[1], via: entry_point)
        backlogs_page.expect_card_menu_loaded(stories[1])

        backlogs_page.dismiss_card_menu(stories[1], via: entry_point)
        backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
      end

      it "replaces an old batch when an unselected card invokes the one-card menu" do
        backlogs_page.select_cards(stories[0], stories[1])

        backlogs_page.open_card_menu(stories[2], via: entry_point)

        backlogs_page.expect_selected_cards_in_order(stories[2])
        backlogs_page.expect_card_menu_loaded(stories[2])

        backlogs_page.dismiss_card_menu(stories[2], via: entry_point)
        backlogs_page.expect_selected_cards_in_order(stories[2])
      end
    end
  end

  it "restores card focus when a contextual batch menu is light-dismissed" do
    backlogs_page.select_cards(stories[0], stories[1])
    backlogs_page.open_card_menu(stories[1], via: :right_click)

    backlogs_page.light_dismiss_card_menu(stories[1])

    backlogs_page.expect_work_package_card_focused(stories[1])
    backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
  end

  it "keeps every singular action bound to its invoking card without collapsing the batch", :aggregate_failures do
    backlogs_page.select_cards(stories[0], stories[1])

    stories.first(2).each do |invoker|
      menu = backlogs_page.open_card_menu(invoker, via: :more)

      expect(menu.find(:menuitem, text: I18n.t(:"js.button_open_details"))[:href])
        .to end_with("/backlogs/backlog/details/#{invoker.id}")
      expect(menu.find(:menuitem, text: I18n.t(:"js.button_open_fullscreen"))[:href])
        .to end_with("/work_packages/#{invoker.id}")
      expect(menu.find(:menuitem, text: "Copy URL to clipboard")[:value])
        .to end_with("/work_packages/#{invoker.id}")
      expect(menu.find(:menuitem, text: "Copy work package ID")[:value]).to eq(invoker.id.to_s)

      backlogs_page.expect_selected_cards_in_order(stories[0], stories[1])
      backlogs_page.dismiss_card_menu(invoker, via: :more)
    end
  end

  it "passes the ordered batch to a destination dialog and a positional move" do
    create(:sprint, project:, name: "Destination")
    backlogs_page.visit!
    backlogs_page.select_contiguous_cards(stories[1], stories[2])

    backlogs_page.activate_batch_menu_action(
      invoker: stories[2],
      action: "Move to sprint",
      via: :context_menu_key
    )
    backlogs_page.expect_destination_dialog("Move to sprint", work_packages: [stories[1], stories[2]])
    backlogs_page.cancel_destination_dialog("Move to sprint")

    backlogs_page.activate_batch_menu_action(
      invoker: stories[1],
      action: "Move down",
      via: :shift_f10
    )

    moved_order = [stories[0], stories[3], stories[1], stories[2]]
    backlogs_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: moved_order)

    backlogs_page.visit!
    backlogs_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: moved_order)
  end

  it "keeps positional actions when the destination intersection is empty" do
    sprint.update_columns(status: "completed")
    inbox_stories = Array.new(3) do |index|
      create(:work_package, project:, type:, position: index + 1)
    end
    backlogs_page.visit!
    backlogs_page.select_contiguous_cards(inbox_stories[0], inbox_stories[1])

    backlogs_page.open_card_menu(inbox_stories[0], via: :right_click)

    backlogs_page.expect_open_menu_actions(
      invoker: inbox_stories[0],
      present: ["Move to position"],
      absent: ["Move to sprint", "Move to backlog bucket", "Move to backlog inbox"]
    )
  end

  it "keeps destination actions when a sparse selection has no valid position" do
    create(:sprint, project:, name: "Destination")
    backlogs_page.visit!
    backlogs_page.select_cards(stories[0], stories[2])

    backlogs_page.open_card_menu(stories[0], via: :more)

    backlogs_page.expect_open_menu_actions(
      invoker: stories[0],
      present: ["Move to sprint"],
      absent: ["Move to position"]
    )
  end

  context "when every card is fixed" do
    let(:permissions) { %i[view_sprints view_work_packages] }

    it "shows the unchanged singular menu for a fixed card" do
      backlogs_page.open_card_menu(stories[0], via: :more)

      backlogs_page.expect_fixed_action_menu(invoker: stories[0])
      backlogs_page.expect_no_selected_cards
    end
  end
end
