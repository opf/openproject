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

RSpec.describe "A read-only work package card in Backlogs",
               :js, :selenium, with_ee: %i[readonly_work_packages] do
  let!(:default_status) { create(:default_status) }
  let!(:rejected_status) { create(:status, :readonly, name: "Rejected") }

  let(:type) { create(:type) }
  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w(work_package_tracking backlogs))
  end

  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i(view_sprints
                           manage_sprint_items
                           view_work_packages
                           edit_work_packages))
  end

  let!(:sprint) { create(:sprint, project:) }
  let!(:other_sprint) { create(:sprint, project:) }

  let!(:movable_wp) { create(:work_package, sprint:, type:, project:, status: default_status) }
  let!(:rejected_wp) { create(:work_package, sprint:, type:, project:, status: rejected_status) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  before do
    backlogs_page.visit!
  end

  it "wears a lock the movable card beside it does not", :aggregate_failures do
    backlogs_page.expect_work_package_locked(rejected_wp)
    backlogs_page.expect_work_package_not_locked(movable_wp)
  end

  it "can be reordered within its own list, and stays a drop target", :aggregate_failures do
    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [movable_wp, rejected_wp])

    backlogs_page.expect_work_package_confined(rejected_wp)

    # The server allows a within-list reorder for a read-only work package —
    # position is not one of its attributes — so the card keeps its drag
    # inside its own list.
    backlogs_page.drag_work_package(rejected_wp, before: movable_wp)
    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [rejected_wp, movable_wp])

    # Dropping a movable neighbour against it proves the read-only card is
    # also still a drop target: confining its drag must not carve a dead zone
    # out of the list.
    backlogs_page.drag_work_package(movable_wp, before: rejected_wp)
    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [movable_wp, rejected_wp])
  end

  it "refuses to leave its sprint by drag", :aggregate_failures do
    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [movable_wp, rejected_wp])

    backlogs_page.drag_work_package_without_move(rejected_wp, into: other_sprint)

    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [movable_wp, rejected_wp])
    expect(rejected_wp.reload.sprint_id).to eq(sprint.id)
  end

  it "offers no move to another container in its menu, but keeps the rest", :aggregate_failures do
    backlogs_page.within_work_package_menu(rejected_wp) do |menu|
      expect(menu).to have_no_selector(:menuitem, text: "Move to sprint")
      expect(menu).to have_no_selector(:menuitem, text: "Move to backlog bucket")
      expect(menu).to have_no_selector(:menuitem, text: "Move to inbox")

      expect(menu).to have_selector(:menuitem, text: "Move to position")
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_details"))
      expect(menu).to have_selector(:menuitem, text: I18n.t(:"js.button_open_fullscreen"))
    end
  end

  # End to end through the same endpoint the drag uses: the UI offers the
  # positional move and the server accepts it, proving the two agree on what a
  # read-only work package may do.
  it "moves within its list through the positional menu actions" do
    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [movable_wp, rejected_wp])

    backlogs_page.click_in_work_package_move_submenu(rejected_wp, I18n.t(:label_sort_highest))

    backlogs_page.expect_sprint_items_in_order(sprint, work_packages: [rejected_wp, movable_wp])
  end

  it "keeps the movement actions on a movable card in the same sprint" do
    backlogs_page.within_work_package_menu(movable_wp) do |menu|
      expect(menu).to have_selector(:menuitem, text: "Move to position")
      expect(menu).to have_selector(:menuitem, text: "Move to sprint")
    end
  end
end
