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

RSpec.describe "Backlogs batch destination menus",
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

  it "moves a selected cross-list batch in live document order and announces its appended range" do
    source_sprint = create(:sprint, project:, name: "Source sprint")
    destination_sprint = create(:sprint, project:, name: "Destination sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    destination_story = create(:work_package, project:, type:, sprint: destination_sprint, position: 1)
    bucket_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 1)
    sprint_story = create(:work_package, project:, type:, sprint: source_sprint, position: 1)
    backlogs_page.visit!

    backlogs_page.select_cards(sprint_story, bucket_story)
    backlogs_page.expect_selected_cards_in_order(bucket_story, sprint_story)

    backlogs_page.open_destination_dialog(sprint_story, "Move to sprint")
    backlogs_page.expect_destination_dialog(
      "Move to sprint",
      work_packages: [bucket_story, sprint_story]
    )
    backlogs_page.submit_destination_dialog(
      "Move to sprint",
      field_label: Sprint.human_model_name,
      option: destination_sprint.name
    )

    backlogs_page.expect_work_packages_in_sprint_in_order(
      destination_sprint,
      work_packages: [destination_story, bucket_story, sprint_story]
    )
    backlogs_page.expect_persisted_sprint_order(
      destination_sprint,
      destination_story,
      bucket_story,
      sprint_story
    )
    backlogs_page.expect_polite_announcement(
      I18n.t(
        "backlogs.work_packages.move_collection.moved_announcement",
        count: 2,
        list: destination_sprint.name,
        first: 2,
        last: 3,
        total: 3
      )
    )
    backlogs_page.expect_no_selected_cards
  end

  it "replaces the old selection when an unselected card invokes a destination action" do
    first_sprint = create(:sprint, project:, name: "First sprint")
    second_sprint = create(:sprint, project:, name: "Second sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    selected_bucket_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 1)
    selected_sprint_story = create(:work_package, project:, type:, sprint: first_sprint, position: 1)
    invoker = create(:work_package, project:, type:, sprint: second_sprint, position: 1)
    backlogs_page.visit!

    backlogs_page.select_cards(selected_sprint_story, selected_bucket_story)
    backlogs_page.expect_selected_cards_in_order(selected_bucket_story, selected_sprint_story)

    backlogs_page.move_to_backlog_inbox(invoker)

    backlogs_page.expect_persisted_inbox_order(invoker)
    backlogs_page.expect_persisted_bucket_order(bucket, selected_bucket_story)
    backlogs_page.expect_persisted_sprint_order(first_sprint, selected_sprint_story)
    backlogs_page.expect_no_selected_cards
  end

  it "offers a partly occupied destination and gathers the whole batch at its end" do
    destination_sprint = create(:sprint, project:, name: "Destination sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    destination_story = create(:work_package, project:, type:, sprint: destination_sprint, position: 1)
    selected_destination_story = create(:work_package, project:, type:, sprint: destination_sprint, position: 2)
    bucket_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 1)
    backlogs_page.visit!

    backlogs_page.select_cards(selected_destination_story, bucket_story)
    backlogs_page.expect_selected_cards_in_order(bucket_story, selected_destination_story)
    backlogs_page.expect_work_package_action(selected_destination_story, "Move to sprint")

    backlogs_page.open_destination_dialog(selected_destination_story, "Move to sprint")
    backlogs_page.expect_destination_dialog_options(
      "Move to sprint",
      field_label: Sprint.human_model_name,
      options: [destination_sprint.name]
    )
    backlogs_page.submit_destination_dialog(
      "Move to sprint",
      field_label: Sprint.human_model_name,
      option: destination_sprint.name
    )

    backlogs_page.expect_persisted_sprint_order(
      destination_sprint,
      destination_story,
      bucket_story,
      selected_destination_story
    )
  end

  it "intersects destinations for confined selections and offers none when their lists conflict" do
    first_sprint = create(:sprint, project:, name: "First sprint")
    second_sprint = create(:sprint, project:, name: "Second sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    readonly_status = create(:status, is_readonly: true)
    confined_first = create(:work_package, project:, type:, sprint: first_sprint, status: readonly_status)
    confined_second = create(:work_package, project:, type:, sprint: second_sprint, status: readonly_status)
    free_story = create(:work_package, project:, type:, backlog_bucket: bucket)
    backlogs_page.visit!

    backlogs_page.select_cards(confined_first, free_story)
    backlogs_page.expect_destination_actions(
      confined_first,
      present: ["Move to sprint"],
      absent: ["Move to backlog bucket", "Move to backlog inbox"]
    )
    backlogs_page.open_destination_dialog(confined_first, "Move to sprint")
    backlogs_page.expect_destination_dialog_options(
      "Move to sprint",
      field_label: Sprint.human_model_name,
      options: [first_sprint.name]
    )
    backlogs_page.cancel_destination_dialog("Move to sprint")
    backlogs_page.clear_card_selection(confined_first)

    backlogs_page.select_cards(confined_first, confined_second)
    backlogs_page.expect_destination_actions(
      confined_first,
      present: [],
      absent: ["Move to sprint", "Move to backlog bucket", "Move to backlog inbox"]
    )
  end

  it "omits Move to position from a multi-card action scope" do
    sprint = create(:sprint, project:, name: "Sprint")
    create(:backlog_bucket, project:, name: "Destination bucket")
    first_story = create(:work_package, project:, type:, sprint:, position: 1)
    second_story = create(:work_package, project:, type:, sprint:, position: 2)
    backlogs_page.visit!

    backlogs_page.select_cards(first_story, second_story)

    backlogs_page.expect_no_work_package_action(first_story, "Move to position")
    backlogs_page.expect_work_package_action(first_story, "Move to backlog bucket")
  end

  it "shows feedback without an empty modal when the last destination disappears before loading" do
    sprint = create(:sprint, project:, name: "Only sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    first_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 1)
    second_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 2)
    backlogs_page.visit!

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.invoke_destination_action_after_menu_load(first_story, "Move to sprint") do
      sprint.update_columns(status: "completed")
    end

    backlogs_page.expect_move_error(
      I18n.t("backlogs.work_packages.move_to_sprint_dialog.no_available_destinations")
    )
    backlogs_page.expect_no_destination_dialog
    backlogs_page.expect_selected_cards_in_order(first_story, second_story)
    backlogs_page.expect_persisted_bucket_order(bucket, first_story, second_story)
  end

  it "rejects the complete batch atomically and retains its selection" do
    sprint = create(:sprint, project:, name: "Destination sprint")
    bucket = create(:backlog_bucket, project:, name: "Source bucket")
    first_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 1)
    second_story = create(:work_package, project:, type:, backlog_bucket: bucket, position: 2)
    backlogs_page.visit!

    backlogs_page.select_cards(first_story, second_story)
    backlogs_page.open_destination_dialog(first_story, "Move to sprint")

    second_story.update_columns(status_id: create(:status, is_readonly: true).id)
    backlogs_page.submit_destination_dialog(
      "Move to sprint",
      field_label: Sprint.human_model_name,
      option: sprint.name,
      frame_reload: false
    )

    backlogs_page.expect_move_error(
      I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
    )
    backlogs_page.expect_persisted_bucket_order(bucket, first_story, second_story)
    backlogs_page.expect_selected_cards_in_order(first_story, second_story)
  end
end
