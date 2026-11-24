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
  let(:live_region) { Components::LiveRegion.new }

  current_user do
    create(:user, member_with_roles: { project => manage_sprint_items_role })
  end

  context "with a single card and no selection" do
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:story) { create(:work_package, project:, type:, sprint:) }

    it "opens the menu the card rendered without rewriting its source" do
      backlogs_page.visit!
      rendered_src = backlogs_page.work_package_menu_src(story)

      backlogs_page.expect_work_package_actions(story, present: ["Move to backlog inbox"])
      backlogs_page.expect_work_package_menu_axe_clean(story)

      expect(backlogs_page.work_package_menu_src(story)).to eq(rendered_src)
    end
  end

  context "with selected members in different source lists" do
    let!(:source_sprint) { create(:sprint, project:, name: "Source sprint") }
    let!(:destination_sprint) { create(:sprint, project:, name: "Destination sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:destination_story) { create(:work_package, project:, type:, sprint: destination_sprint) }
    let!(:bucket_story) { create(:work_package, project:, type:, backlog_bucket: bucket) }
    let!(:sprint_story) { create(:work_package, project:, type:, sprint: source_sprint) }

    it "names the menu after the batch only while it is open", :aggregate_failures do
      backlogs_page.visit!
      backlogs_page.select_cards(sprint_story, bucket_story)

      backlogs_page.within_work_package(sprint_story) do
        find(:button, accessible_name: "Work package actions").click
        expect(page).to have_button(accessible_name: "Actions for 2 selected work packages")
      end
      expect(page).to have_selector(:menu, accessible_name: "Actions for 2 selected work packages")

      backlogs_page.send_keys_to_focused_element(:escape)

      expect(page).to have_no_selector(:menu)
      backlogs_page.within_work_package(sprint_story) do
        expect(page).to have_button(accessible_name: "Work package actions")
      end
    end

    it "moves the batch to a sprint in document order and announces its range" do
      backlogs_page.visit!

      backlogs_page.select_cards(sprint_story, bucket_story)
      backlogs_page.expect_selected_cards_in_order(bucket_story, sprint_story)
      backlogs_page.expect_work_package_menu_axe_clean(sprint_story)

      backlogs_page.open_destination_dialog(sprint_story, "Move to sprint")
      backlogs_page.expect_destination_dialog("Move to sprint", work_packages: [bucket_story, sprint_story])
      backlogs_page.expect_destination_dialog_axe_clean("Move to sprint")
      backlogs_page.submit_destination_dialog("Move to sprint", option: "Destination sprint")

      backlogs_page.expect_sprint_items_in_order(
        destination_sprint,
        items: [destination_story, bucket_story, sprint_story]
      )
      live_region.expect_announcement(
        "2 work packages moved to Destination sprint, positions 2 through 3 of 3"
      )
      backlogs_page.expect_no_selected_cards
      backlogs_page.expect_backlogs_axe_clean

      backlogs_page.visit!
      backlogs_page.expect_sprint_items_in_order(
        destination_sprint,
        items: [destination_story, bucket_story, sprint_story]
      )
    end

    it "shows loaded batch actions when reopened for the same selection" do
      backlogs_page.visit!
      backlogs_page.select_cards(sprint_story, bucket_story)

      backlogs_page.expect_work_package_actions(sprint_story, present: ["Move to sprint"])

      invoker_row = backlogs_page.work_package_row(sprint_story)
      backlogs_page.within_work_package_menu(sprint_story, activated: true) do |menu|
        expect(invoker_row).to have_button(accessible_name: "Actions for 2 selected work packages")
        expect(menu).to have_selector(:menuitem, text: "Move to sprint", exact_text: true)
        expect(menu).to have_no_css("include-fragment", visible: :all)
        menu.find(:menuitem, text: "Move to sprint", exact_text: true).click
      end

      backlogs_page.expect_destination_dialog("Move to sprint", work_packages: [bucket_story, sprint_story])
    end
  end

  context "with an unselected invoker" do
    let!(:first_sprint) { create(:sprint, project:, name: "First sprint") }
    let!(:second_sprint) { create(:sprint, project:, name: "Second sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:selected_bucket_story) { create(:work_package, project:, type:, backlog_bucket: bucket) }
    let!(:selected_sprint_story) { create(:work_package, project:, type:, sprint: first_sprint) }
    let!(:invoker) { create(:work_package, project:, type:, sprint: second_sprint) }

    it "moves only the invoker and drops the earlier selection" do
      backlogs_page.visit!

      backlogs_page.select_cards(selected_sprint_story, selected_bucket_story)
      backlogs_page.expect_selected_cards_in_order(selected_bucket_story, selected_sprint_story)

      backlogs_page.move_to_backlog_inbox(invoker)

      backlogs_page.expect_inbox_items_in_order(items: [invoker])
      backlogs_page.expect_bucket_items_in_order(bucket, items: [selected_bucket_story])
      backlogs_page.expect_sprint_items_in_order(first_sprint, items: [selected_sprint_story])
      backlogs_page.expect_no_selected_cards

      backlogs_page.visit!
      backlogs_page.expect_inbox_items_in_order(items: [invoker])
      backlogs_page.expect_bucket_items_in_order(bucket, items: [selected_bucket_story])
      backlogs_page.expect_sprint_items_in_order(first_sprint, items: [selected_sprint_story])
    end
  end

  context "with a partly occupied destination" do
    let!(:destination_sprint) { create(:sprint, project:, name: "Destination sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:destination_story) { create(:work_package, project:, type:, sprint: destination_sprint, position: 1) }
    let!(:selected_destination_story) do
      create(:work_package, project:, type:, sprint: destination_sprint, position: 2)
    end
    let!(:bucket_story) { create(:work_package, project:, type:, backlog_bucket: bucket) }

    it "offers the destination and gathers the whole batch at its end" do
      backlogs_page.visit!

      backlogs_page.select_cards(selected_destination_story, bucket_story)
      backlogs_page.expect_selected_cards_in_order(bucket_story, selected_destination_story)

      backlogs_page.open_destination_dialog(selected_destination_story, "Move to sprint")
      backlogs_page.expect_destination_dialog_options("Move to sprint", options: ["Destination sprint"])
      backlogs_page.submit_destination_dialog("Move to sprint", option: "Destination sprint")

      backlogs_page.expect_sprint_items_in_order(
        destination_sprint,
        items: [destination_story, bucket_story, selected_destination_story]
      )

      backlogs_page.visit!
      backlogs_page.expect_sprint_items_in_order(
        destination_sprint,
        items: [destination_story, bucket_story, selected_destination_story]
      )
    end
  end

  context "with read-only members" do
    let!(:first_sprint) { create(:sprint, project:, name: "First sprint") }
    let!(:second_sprint) { create(:sprint, project:, name: "Second sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:readonly_status) { create(:status, is_readonly: true) }
    let!(:confined_first) { create(:work_package, project:, type:, sprint: first_sprint, status: readonly_status) }
    let!(:confined_second) { create(:work_package, project:, type:, sprint: second_sprint, status: readonly_status) }
    let!(:free_story) { create(:work_package, project:, type:, backlog_bucket: bucket) }

    it "offers only the destinations every member may move to" do
      backlogs_page.visit!

      backlogs_page.select_cards(confined_first, free_story)
      backlogs_page.expect_work_package_actions(
        confined_first,
        present: ["Move to sprint"],
        absent: ["Move to backlog bucket", "Move to backlog inbox"]
      )
      backlogs_page.open_destination_dialog(confined_first, "Move to sprint")
      backlogs_page.expect_destination_dialog_options("Move to sprint", options: ["First sprint"])
      backlogs_page.cancel_destination_dialog("Move to sprint")
      backlogs_page.clear_card_selection(confined_first)

      backlogs_page.select_cards(confined_first, confined_second)
      backlogs_page.expect_work_package_actions(
        confined_first,
        absent: ["Move to sprint", "Move to backlog bucket", "Move to backlog inbox"]
      )
    end
  end

  context "with a contiguous multi-card action scope" do
    let!(:sprint) { create(:sprint, project:, name: "Sprint") }
    let!(:destination_bucket) { create(:backlog_bucket, project:, name: "Destination bucket") }
    let!(:first_story) { create(:work_package, project:, type:, sprint:, position: 1) }
    let!(:second_story) { create(:work_package, project:, type:, sprint:, position: 2) }
    let!(:third_story) { create(:work_package, project:, type:, sprint:, position: 3) }

    it "offers Move to position for a contiguous multi-card action scope" do
      backlogs_page.visit!

      backlogs_page.select_cards(first_story, second_story)

      backlogs_page.expect_move_to_position_available(first_story, action: "Move down")
      backlogs_page.expect_work_package_actions(first_story, present: ["Move to backlog bucket"])
    end
  end

  context "when the last destination disappears before the dialog loads" do
    let!(:sprint) { create(:sprint, project:, name: "Only sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:first_story) { create(:work_package, project:, type:, backlog_bucket: bucket, position: 1) }
    let!(:second_story) { create(:work_package, project:, type:, backlog_bucket: bucket, position: 2) }

    it "shows an error instead of an empty dialog and keeps the selection" do
      backlogs_page.visit!

      backlogs_page.select_cards(first_story, second_story)
      backlogs_page.invoke_destination_action_after_menu_load(first_story, "Move to sprint") do
        sprint.update_columns(status: "completed")
      end

      backlogs_page.expect_move_error("There are no available sprints for these work packages.")
      backlogs_page.expect_no_destination_dialog
      backlogs_page.expect_selected_cards_in_order(first_story, second_story)
      backlogs_page.expect_bucket_items_in_order(bucket, items: [first_story, second_story])
    end
  end

  context "when a batch member refuses the destination" do
    let!(:sprint) { create(:sprint, project:, name: "Destination sprint") }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Source bucket") }
    let!(:first_story) { create(:work_package, project:, type:, backlog_bucket: bucket, position: 1) }
    let!(:second_story) { create(:work_package, project:, type:, backlog_bucket: bucket, position: 2) }

    it "rejects the whole batch and keeps the selection" do
      backlogs_page.visit!

      backlogs_page.select_cards(first_story, second_story)
      backlogs_page.open_destination_dialog(first_story, "Move to sprint")

      second_story.update_columns(status_id: create(:status, is_readonly: true).id)
      backlogs_page.submit_destination_dialog("Move to sprint", option: "Destination sprint", frame_reload: false)

      backlogs_page.expect_move_error(
        "#{second_story.reload.to_fs(:caption)}: " \
        "The destination list is no longer available. Please reload the page and try again."
      )
      backlogs_page.expect_bucket_items_in_order(bucket, items: [first_story, second_story])
      backlogs_page.expect_selected_cards_in_order(first_story, second_story)

      backlogs_page.visit!
      backlogs_page.expect_bucket_items_in_order(bucket, items: [first_story, second_story])
    end
  end

  context "with a selected batch moving to a backlog bucket" do
    let!(:sprint) { create(:sprint, project:) }
    let!(:bucket) { create(:backlog_bucket, project:, name: "Destination bucket") }
    let!(:existing) { create(:work_package, project:, type:, backlog_bucket: bucket) }
    let!(:first) { create(:work_package, project:, type:, sprint:, position: 1) }
    let!(:second) { create(:work_package, project:, type:, sprint:, position: 2) }

    it "appends the ordered batch and announces its range" do
      backlogs_page.visit!
      backlogs_page.select_cards(first, second)
      backlogs_page.open_destination_dialog(first, "Move to backlog bucket")
      backlogs_page.expect_destination_dialog("Move to backlog bucket", work_packages: [first, second])
      backlogs_page.expect_destination_dialog_axe_clean("Move to backlog bucket")
      backlogs_page.submit_destination_dialog("Move to backlog bucket", option: "Destination bucket")

      backlogs_page.expect_bucket_items_in_order(bucket, items: [existing, first, second])
      live_region.expect_announcement(
        "2 work packages moved to Destination bucket, positions 2 through 3 of 3"
      )
      backlogs_page.expect_no_selected_cards

      backlogs_page.visit!
      backlogs_page.expect_bucket_items_in_order(bucket, items: [existing, first, second])
    end
  end

  context "with a selected batch moving to the inbox" do
    let!(:sprint) { create(:sprint, project:) }
    let!(:existing) { create(:work_package, project:, type:) }
    let!(:first) { create(:work_package, project:, type:, sprint:, position: 1) }
    let!(:second) { create(:work_package, project:, type:, sprint:, position: 2) }

    it "appends the whole selection and announces its range" do
      backlogs_page.visit!
      backlogs_page.select_cards(first, second)
      backlogs_page.move_to_backlog_inbox(first)

      backlogs_page.expect_inbox_items_in_order(items: [existing, first, second])
      live_region.expect_announcement("2 work packages moved to Inbox, positions 2 through 3 of 3")
      backlogs_page.expect_no_selected_cards

      backlogs_page.visit!
      backlogs_page.expect_inbox_items_in_order(items: [existing, first, second])
    end
  end

  context "with an additive selection followed by a shrinking Shift range" do
    let!(:source) { create(:sprint, project:, name: "Source sprint") }
    let!(:destination) { create(:sprint, project:, name: "Destination sprint") }
    let!(:existing) { create(:work_package, project:, type:, sprint: destination, subject: "X") }
    let!(:stories) do
      %w[A B C D E].map.with_index(1) do |subject, position|
        create(:work_package, project:, type:, sprint: source, subject:, position:)
      end
    end

    it "moves the current range together with the earlier additive member" do
      a, b, c, d, e = stories
      backlogs_page.visit!
      backlogs_page.toggle_card(a)
      backlogs_page.toggle_card(c)
      backlogs_page.extend_selection_to(e)
      backlogs_page.expect_selected_cards_in_order(a, c, d, e)
      backlogs_page.extend_selection_to(d)
      backlogs_page.expect_selected_cards_in_order(a, c, d)

      backlogs_page.open_destination_dialog(c, "Move to sprint")
      backlogs_page.expect_destination_dialog("Move to sprint", work_packages: [a, c, d])
      backlogs_page.submit_destination_dialog("Move to sprint", option: "Destination sprint")

      backlogs_page.expect_sprint_items_in_order(destination, items: [existing, a, c, d])
      backlogs_page.expect_sprint_items_in_order(source, items: [b, e])
      backlogs_page.expect_no_selected_cards

      backlogs_page.visit!
      backlogs_page.expect_sprint_items_in_order(destination, items: [existing, a, c, d])
      backlogs_page.expect_sprint_items_in_order(source, items: [b, e])
    end
  end
end
