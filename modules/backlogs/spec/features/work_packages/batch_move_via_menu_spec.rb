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

RSpec.describe "Move selected backlog cards to a position via their menu",
               :js,
               :selenium,
               :settings_reset,
               with_ee: %i[readonly_work_packages] do
  let!(:project) do
    create(:project, types: [type], enabled_module_names: %w(work_package_tracking backlogs))
  end
  let(:type) { create(:type) }
  let(:manage_sprint_items_role) do
    create(:project_role,
           permissions: %i[view_sprints manage_sprint_items view_work_packages edit_work_packages])
  end
  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  def create_sprint_stories(sprint, count: 6, status: nil)
    Array.new(count) do |index|
      create(:work_package, **{ project:, type:, sprint:, status:, position: index + 1 }.compact)
    end
  end

  it "moves a contiguous block to the top and then down while preserving its order" do
    sprint = create(:sprint, project:, name: "Sprint")
    stories = create_sprint_stories(sprint)
    backlogs_page.visit!

    backlogs_page.select_contiguous_cards(stories[2], stories[3])
    backlogs_page.expect_move_to_position_available(stories[2], action: "Move to top")
    backlogs_page.move_selected_cards(invoker: stories[2], action: "Move to top")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[2], stories[3], stories[0], stories[1], stories[4], stories[5]]
    )
    backlogs_page.expect_polite_announcement("2 work packages moved to positions 1 through 2 of 6")
    backlogs_page.expect_persisted_sprint_order(
      sprint,
      stories[2], stories[3], stories[0], stories[1], stories[4], stories[5]
    )
    backlogs_page.expect_no_selected_cards

    backlogs_page.select_contiguous_cards(stories[2], stories[3])
    backlogs_page.move_selected_cards(invoker: stories[3], action: "Move down")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[0], stories[2], stories[3], stories[1], stories[4], stories[5]]
    )
    backlogs_page.expect_persisted_sprint_order(
      sprint,
      stories[0], stories[2], stories[3], stories[1], stories[4], stories[5]
    )
  end

  it "moves a contiguous block to the bottom and then up while preserving its order" do
    sprint = create(:sprint, project:, name: "Sprint")
    stories = create_sprint_stories(sprint)
    backlogs_page.visit!

    backlogs_page.select_contiguous_cards(stories[2], stories[3])
    backlogs_page.move_selected_cards(invoker: stories[3], action: "Move to bottom")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[0], stories[1], stories[4], stories[5], stories[2], stories[3]]
    )
    backlogs_page.expect_persisted_sprint_order(
      sprint,
      stories[0], stories[1], stories[4], stories[5], stories[2], stories[3]
    )
    backlogs_page.expect_no_selected_cards

    backlogs_page.select_contiguous_cards(stories[2], stories[3])
    backlogs_page.move_selected_cards(invoker: stories[2], action: "Move up")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[0], stories[1], stories[4], stories[2], stories[3], stories[5]]
    )
    backlogs_page.expect_persisted_sprint_order(
      sprint,
      stories[0], stories[1], stories[4], stories[2], stories[3], stories[5]
    )
  end

  it "keeps the singular menu contract for an unselected card" do
    sprint = create(:sprint, project:, name: "Sprint")
    stories = create_sprint_stories(sprint, count: 3)
    backlogs_page.visit!

    backlogs_page.expect_move_to_position_available(stories[1], action: "Move up")
    backlogs_page.move_selected_cards(invoker: stories[1], action: "Move up")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[1], stories[0], stories[2]]
    )
    backlogs_page.expect_polite_announcement("#{stories[1].to_fs(:caption)} moved to position 1 of 3")
    backlogs_page.expect_persisted_sprint_order(sprint, stories[1], stories[0], stories[2])
  end

  it "omits positional actions for sparse and cross-list selections" do
    sprint = create(:sprint, project:, name: "Sprint")
    other_sprint = create(:sprint, project:, name: "Other sprint")
    stories = create_sprint_stories(sprint, count: 4)
    other_story = create(:work_package, project:, type:, sprint: other_sprint)
    backlogs_page.visit!

    backlogs_page.select_cards(stories[0], stories[2])
    backlogs_page.expect_move_to_position_unavailable(stories[0])
    backlogs_page.clear_card_selection(stories[0])

    backlogs_page.select_cards(stories[0], other_story)
    backlogs_page.expect_move_to_position_unavailable(stories[0])
  end

  it "moves a contiguous confined block within its list" do
    sprint = create(:sprint, project:, name: "Sprint")
    readonly_status = create(:status, is_readonly: true)
    stories = create_sprint_stories(sprint, count: 4, status: readonly_status)
    backlogs_page.visit!

    backlogs_page.select_contiguous_cards(stories[1], stories[2])
    backlogs_page.expect_move_to_position_available(stories[1], action: "Move down")
    backlogs_page.move_selected_cards(invoker: stories[1], action: "Move down")

    backlogs_page.expect_work_packages_in_sprint_in_order(
      sprint,
      work_packages: [stories[0], stories[3], stories[1], stories[2]]
    )
    backlogs_page.expect_persisted_sprint_order(sprint, stories[0], stories[3], stories[1], stories[2])
  end

  it "omits one-step actions at truncation boundaries and block no-ops" do
    stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 2)
    inbox_stories = Array.new(5) do |index|
      create(:work_package, project:, type:, position: index + 1)
    end
    backlogs_page.visit!

    backlogs_page.select_contiguous_cards(inbox_stories[0], inbox_stories[1])
    backlogs_page.expect_move_to_position_unavailable(inbox_stories[0], action: "Move down")
    backlogs_page.expect_move_to_position_unavailable(inbox_stories[0], action: "Move to top")
    backlogs_page.clear_card_selection(inbox_stories[0])

    backlogs_page.select_cards(inbox_stories.last)
    backlogs_page.expect_move_to_position_unavailable(inbox_stories.last, action: "Move to bottom")
  end

  it "rolls a rejected move back and preserves the selected block" do
    sprint = create(:sprint, project:, name: "Sprint")
    stories = create_sprint_stories(sprint, count: 4)
    backlogs_page.visit!

    backlogs_page.select_contiguous_cards(stories[1], stories[2])
    stories[2].destroy!
    backlogs_page.move_selected_cards(invoker: stories[1], action: "Move down")

    backlogs_page.expect_move_error(
      I18n.t("backlogs.work_packages.move_collection.work_packages_not_found")
    )
    backlogs_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: stories)
    backlogs_page.expect_selected_cards_in_order(stories[1], stories[2])
  end
end
