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

require "spec_helper"
require_relative "../../support/pages/backlog"

RSpec.describe "Backlog card menus restored or morphed by Turbo",
               :js,
               :selenium do
  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i[view_sprints manage_sprint_items view_work_packages edit_work_packages])
  end
  let!(:sprint) { create(:sprint, project:, name: "Sprint") }
  let!(:first_story) { create(:work_package, project:, type:, sprint:, position: 1) }
  let!(:second_story) { create(:work_package, project:, type:, sprint:, position: 2) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "loads a menu that was loaded before leaving for the current selection" do
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])

    backlogs_page.leave_for_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
    expect(page).to have_selector(:menuitem, text: "Move to backlog inbox")
    expect(page).to have_no_selector(:menuitem, text: "Open details view")
  end

  it "restores the singular menu of a page cached while its batch menu was open" do
    backlogs_page.leave_for_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")

    backlogs_page.go_forward_to_all_sprints
    backlogs_page.go_back_to_backlogs

    backlogs_page.within_work_package(first_story) do
      expect(page).to have_button(accessible_name: "Work package actions")
    end
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])
  end

  it "loads a menu that was loaded before a morphing refresh" do
    backlogs_page.expect_work_package_actions(first_story, present: ["Open details view"])

    backlogs_page.move_to_backlog_inbox(second_story)
    backlogs_page.expect_inbox_items_in_order(items: [second_story])

    backlogs_page.within_work_package_menu(first_story) do |menu|
      expect(menu).to have_selector(:menuitem, text: "Open details view", focused: true)
    end
    backlogs_page.expect_selected_cards_in_order(first_story)

    backlogs_page.toggle_card(second_story)
    backlogs_page.expect_selected_cards_in_order(second_story, first_story)
    backlogs_page.open_work_package_menu(first_story)
    expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")
    expect(page).to have_selector(:menuitem, text: "Move to sprint")
    expect(page).to have_no_selector(:menuitem, text: "Open details view")
  end
end
