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
require_relative "../support/pages/backlog"

RSpec.describe "Inbox column in sprint planning view", :js do
  let(:sprint_sharing) { nil }
  let!(:project) do
    create(:project,
           types: [type],
           enabled_module_names: %w[work_package_tracking backlogs],
           sprint_sharing:)
  end
  let!(:type) { create(:type) }
  let(:base_permissions) do
    %i[
      view_project
      view_sprints
      manage_sprint_items
      add_work_packages
      view_work_packages
      edit_work_packages
    ]
  end
  let(:additional_permissions) { [] }
  let(:permissions) { base_permissions + additional_permissions }
  let!(:role) do
    create(:project_role, permissions:)
  end
  let(:user_password) { "bob" * 4 }
  let!(:current_user) do
    create(:user,
           member_with_roles: { project => role },
           password: user_password,
           password_confirmation: user_password)
  end

  let(:planning_page) { Pages::Backlog.new(project) }

  before do
    login_as current_user
  end

  context "when the inbox has no work packages" do
    let!(:sprint) { create(:sprint, name: "Sprint 1", project:) }

    before { planning_page.visit! }

    it "shows the blankslate" do
      planning_page.expect_inbox_blankslate
    end
  end

  context "when there are no sprints" do
    before { planning_page.visit! }

    context "when the user can create sprints and manage sprint sharing" do
      let(:additional_permissions) { %i[create_sprints share_sprint] }

      it "shows the sprint blankslate with settings link and sprint button" do
        planning_page.expect_inbox_blankslate
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "To start planning your sprint, create one here or go to the project settings to receive sprints from a different project."
        )
        planning_page.expect_backlog_settings_link
        planning_page.expect_new_sprint_button
      end
    end

    context "when the user cannot manage sprint sharing" do
      let(:additional_permissions) { %i[create_sprints] }

      it "shows the sprint blankslate without the settings link" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_no_backlog_settings_link
        planning_page.expect_sprints_blankslate_description(
          "To start planning your sprint, create one here."
        )
        planning_page.expect_new_sprint_button
      end
    end

    context "when the user can manage sprint sharing but cannot create sprints" do
      let(:additional_permissions) { %i[share_sprint] }

      it "shows the sprint blankslate with settings link but no sprint button" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "To start planning your sprint, go to the project settings to receive sprints from a different project."
        )
        planning_page.expect_backlog_settings_link
        planning_page.expect_no_new_sprint_button
      end
    end

    context "when the user cannot create sprints or manage sprint sharing" do
      it "shows the sprint blankslate without action copy, settings link, or sprint button" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "No sprints are available for this project yet."
        )
        planning_page.expect_no_backlog_settings_link
        planning_page.expect_no_new_sprint_button
      end
    end
  end

  context "when the project receives shared sprints" do
    let(:sprint_sharing) { "receive_shared" }

    before { planning_page.visit! }

    context "when the user can manage sprint sharing" do
      let(:additional_permissions) { %i[create_sprints share_sprint] }

      it "shows the sprint blankslate without a sprint button and keeps the settings link" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "This project receives sprints from a different project. Manage this in the project settings."
        )
        planning_page.expect_backlog_settings_link
        planning_page.expect_no_new_sprint_button
      end
    end

    context "when the user cannot manage sprint sharing" do
      it "shows the sprint blankslate without settings link or sprint button" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "This project receives shared sprints from a different project, but none are available right now."
        )
        planning_page.expect_no_backlog_settings_link
        planning_page.expect_no_new_sprint_button
      end
    end

    context "when the user can create sprints but cannot manage sprint sharing" do
      let(:additional_permissions) { %i[create_sprints] }

      it "shows the sprint blankslate without settings link or sprint button" do
        planning_page.expect_sprints_blankslate
        planning_page.expect_sprints_blankslate_description(
          "This project receives shared sprints from a different project, but none are available right now."
        )
        planning_page.expect_no_backlog_settings_link
        planning_page.expect_no_new_sprint_button
      end
    end

    context "when a shared sprint is available" do
      let!(:source_project) do
        create(:project,
               sprint_sharing: "share_all_projects",
               types: [type],
               enabled_module_names: %w[work_package_tracking backlogs])
      end
      let!(:shared_sprint) { create(:sprint, name: "Shared Sprint", project: source_project) }

      before { planning_page.visit! }

      it "renders the shared sprint instead of the blankslate" do
        planning_page.expect_no_sprints_blankslate
        planning_page.expect_sprint_names_in_order("Shared Sprint")
      end
    end
  end

  context "when a sprint is present" do
    let!(:sprint) { create(:sprint, name: "Sprint 1", project:) }

    before { planning_page.visit! }

    it "renders the sprint and hides the sprint blankslate" do
      planning_page.expect_no_sprints_blankslate
      planning_page.expect_sprint_names_in_order("Sprint 1")
    end
  end

  context "with work packages in the inbox" do
    let!(:sprint) { create(:sprint, name: "Sprint 1", project:) }
    let!(:inbox_wp1) { create(:work_package, project:) }
    let!(:inbox_wp2) { create(:work_package, project:) }
    let!(:inbox_wp3) { create(:work_package, project:) }

    before { planning_page.visit! }

    it "displays all items in position order and hides the blankslate" do
      planning_page.expect_inbox_item(inbox_wp1)
      planning_page.expect_inbox_item(inbox_wp2)
      planning_page.expect_inbox_item(inbox_wp3)
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1, inbox_wp2, inbox_wp3])
      planning_page.expect_no_inbox_blankslate
    end

    it "allows reordering items via the kebab menu", :aggregate_failures do
      # First item has no upward actions

      planning_page.within_work_package_move_submenu(inbox_wp1) do |submenu|
        expect(submenu).to have_no_selector(:menuitem, text: "Move to top")
        expect(submenu).to have_no_selector(:menuitem, text: "Move up")
        expect(submenu).to have_selector(:menuitem, text: "Move down")
        expect(submenu).to have_selector(:menuitem, text: "Move to bottom")
      end

      # Last item has no downward actions
      planning_page.within_work_package_move_submenu(inbox_wp3) do |submenu|
        expect(submenu).to have_selector(:menuitem, text: "Move to top")
        expect(submenu).to have_selector(:menuitem, text: "Move up")
        expect(submenu).to have_no_selector(:menuitem, text: "Move down")
        expect(submenu).to have_no_selector(:menuitem, text: "Move to bottom")
      end

      wait_for_network_idle

      planning_page.click_in_work_package_move_submenu(inbox_wp1, "Move down")
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2, inbox_wp1, inbox_wp3])

      planning_page.click_in_work_package_move_submenu(inbox_wp1, "Move down")
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2, inbox_wp3, inbox_wp1])

      planning_page.click_in_work_package_move_submenu(inbox_wp2, "Move to bottom")
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp3, inbox_wp1, inbox_wp2])

      planning_page.click_in_work_package_move_submenu(inbox_wp2, "Move to top")
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2, inbox_wp3, inbox_wp1])

      planning_page.click_in_work_package_move_submenu(inbox_wp1, "Move up")
      planning_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp2, inbox_wp1, inbox_wp3])
    end

    describe "moving backlog items to a sprint via the 'Move to sprint' menu item" do
      let!(:sprint2) { create(:sprint, name: "Sprint 2", project:) }
      let!(:sprint_wp) { create(:work_package, project:, sprint:) }

      before { planning_page.visit! }

      it "moves the item to the bottom of the selected sprint" do
        planning_page.click_in_work_package_menu(inbox_wp1, "Move to sprint", wait: false)

        within_modal "Move to sprint" do
          # Expect to have all sprints listed
          expect(page).to have_select("target_id", with_options: ["Sprint 1", "Sprint 2"])

          select sprint.name, from: "target_id"
          click_button "Move"
        end

        planning_page.expect_no_inbox_item(inbox_wp1)
        planning_page.expect_work_package_in_sprint(inbox_wp1, sprint)
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [sprint_wp, inbox_wp1])
      end

      context "when the target sprint is completed (race condition #73750)" do
        it "shows an error and does not move the item" do
          planning_page.click_in_work_package_menu(inbox_wp1, "Move to sprint", wait: false)

          within_modal "Move to sprint" do
            expect(page).to have_select("target_id", with_options: ["Sprint 1", "Sprint 2"])
            select sprint.name, from: "target_id"

            # Before saving the selection, simulate that another user completed the sprint
            sprint.completed!

            click_button "Move"
          end

          planning_page
            .expect_and_dismiss_error(
              "Update failed: Sprint is not assignable since it is either not shared with the project or already finished."
            )

          # Item was *not* moved:
          planning_page.expect_inbox_item(inbox_wp1)
          planning_page.expect_work_package_not_in_sprint(inbox_wp1, sprint)
        end
      end
    end

    describe "moving backlog items to a sprint via drag-and-drop" do
      it "moves multiple items into the sprint one by one" do
        planning_page.drag_work_package_to_sprint(inbox_wp1, sprint)
        planning_page.expect_no_inbox_item(inbox_wp1)

        planning_page.drag_work_package_to_sprint(inbox_wp2, sprint)
        planning_page.expect_no_inbox_item(inbox_wp2)

        planning_page.drag_work_package_to_sprint(inbox_wp3, sprint)
        planning_page.expect_no_inbox_item(inbox_wp3)

        planning_page.expect_inbox_blankslate
        planning_page.expect_work_package_in_sprint(inbox_wp1, sprint)
        planning_page.expect_work_package_in_sprint(inbox_wp2, sprint)
        planning_page.expect_work_package_in_sprint(inbox_wp3, sprint)
      end

      context "with real authentication and a private project" do
        let!(:project) do
          create(:private_project,
                 types: [type],
                 enabled_module_names: %w[work_package_tracking backlogs],
                 sprint_sharing:)
        end

        before do
          logout
          login_with(current_user.login, user_password)
          planning_page.visit!
        end

        it "moves a backlog item to the sprint without an error (Regression#73416)" do
          planning_page.drag_work_package_to_sprint(inbox_wp1, sprint)
          planning_page.expect_no_inbox_item(inbox_wp1)
        end
      end
    end

    describe "reordering sprint items via the kebab menu" do
      let!(:sprint_wp1) { create(:work_package, project:, sprint:) }
      let!(:sprint_wp2) { create(:work_package, project:, sprint:) }
      let!(:sprint_wp3) { create(:work_package, project:, sprint:) }

      before { planning_page.visit! }

      it "allows reordering items", :aggregate_failures do
        items_in_visual_order = planning_page.sprint_items_in_visual_order(sprint, sprint_wp1, sprint_wp2, sprint_wp3)
        top_item = items_in_visual_order[0]
        middle_item = items_in_visual_order[1]
        bottom_item = items_in_visual_order[2]

        # First item has no upward actions
        planning_page.within_work_package_move_submenu(top_item) do |submenu|
          expect(submenu).to have_no_selector(:menuitem, text: "Move to top")
          expect(submenu).to have_no_selector(:menuitem, text: "Move up")
          expect(submenu).to have_selector(:menuitem, text: "Move down")
          expect(submenu).to have_selector(:menuitem, text: "Move to bottom")
        end

        # Last item has no downward actions
        planning_page.within_work_package_move_submenu(bottom_item) do |submenu|
          expect(submenu).to have_selector(:menuitem, text: "Move to top")
          expect(submenu).to have_selector(:menuitem, text: "Move up")
          expect(submenu).to have_no_selector(:menuitem, text: "Move down")
          expect(submenu).to have_no_selector(:menuitem, text: "Move to bottom")
        end

        planning_page.click_in_work_package_move_submenu(top_item, "Move down")
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [middle_item, top_item, bottom_item])

        planning_page.click_in_work_package_move_submenu(top_item, "Move down")
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [middle_item, bottom_item, top_item])

        planning_page.click_in_work_package_move_submenu(middle_item, "Move to bottom")
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [bottom_item, top_item, middle_item])

        planning_page.click_in_work_package_move_submenu(middle_item, "Move to top")
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [middle_item, bottom_item, top_item])

        planning_page.click_in_work_package_move_submenu(top_item, "Move up")
        planning_page.expect_work_packages_in_sprint_in_order(sprint, work_packages: [middle_item, top_item, bottom_item])
      end
    end

    describe "moving sprint items back to the inbox via drag-and-drop" do
      let!(:sprint_wp1) { create(:work_package, project:, sprint:) }
      let!(:sprint_wp2) { create(:work_package, project:, sprint:) }

      before { planning_page.visit! }

      it "moves all sprint items back to the inbox" do
        planning_page.drag_work_package_to_backlog_inbox(sprint_wp1)
        wait_for_network_idle

        planning_page.drag_work_package_to_backlog_inbox(sprint_wp2)
        wait_for_network_idle

        planning_page.expect_work_package_not_in_sprint(sprint_wp1, sprint)
        planning_page.expect_work_package_not_in_sprint(sprint_wp2, sprint)
        planning_page.expect_inbox_item(sprint_wp1)
        planning_page.expect_inbox_item(sprint_wp2)
      end

      context "when the sprint item is configured to be excluded from backlogs" do
        let!(:status) { create(:status) }
        let!(:sprint_wp1) { create(:work_package, project:, sprint:, status:) }

        before do
          project.done_statuses << status
          planning_page.visit!
        end

        it "hides the work package after move and shows an explanation" do
          planning_page.drag_work_package_to_backlog_inbox(sprint_wp1)
          wait_for_network_idle

          message =
            "The work package was moved to Inbox but is not visible because " \
            "its type or status is excluded from the backlog."

          planning_page.expect_and_dismiss_flash(message:, type: :default)
          planning_page.expect_work_package_not_in_sprint(sprint_wp1, sprint)
          planning_page.expect_no_inbox_item(sprint_wp1)
        end
      end
    end
  end

  describe "retaining the 'show all' state" do
    let!(:sprint) { create(:sprint, name: "Sprint 1", project:) }
    let!(:inbox_items) { create_list(:work_package, 5, project:, type:) }
    let!(:sprint_wp1) { create(:work_package, project:, sprint:, type:) }
    let!(:sprint_wp2) { create(:work_package, project:, sprint:, type:) }

    before do
      stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 2)
      planning_page.visit!
    end

    it "retains the expanded inbox across all update actions", :aggregate_failures do
      # Initial load shows pagination
      planning_page.expect_inbox_show_more

      # Expand inbox — URL advances to ?all=1
      planning_page.click_inbox_show_more
      expect(page.current_url).to include("all=1")
      planning_page.expect_no_inbox_show_more

      # Drag an inbox item to the sprint
      planning_page.drag_work_package_to_sprint(inbox_items.first, sprint)
      planning_page.expect_no_inbox_show_more

      # Reorder within the inbox via menu
      planning_page.click_in_work_package_move_submenu(inbox_items.last, "Move up")
      planning_page.expect_no_inbox_show_more

      # Reorder within the sprint via menu
      planning_page.click_in_work_package_move_submenu(sprint_wp1, "Move down")
      planning_page.expect_no_inbox_show_more

      # Move an inbox item to the sprint via the dialog
      planning_page.click_in_work_package_menu(inbox_items.last, "Move to sprint", wait: false)
      within_modal "Move to sprint" do
        select sprint.name, from: "target_id"
        click_button "Move"
      end
      planning_page.expect_no_inbox_show_more

      # Open a sprint story details view, edit the subject, and close
      details_view = planning_page.open_work_package_details(sprint_wp1)
      details_view.edit_field("subject").update("Updated subject")
      details_view.expect_and_dismiss_toaster message: "Successful update."
      details_view.close

      planning_page.expect_no_inbox_show_more
    end

    it "does not show the 'show more' button when navigating directly with ?all=1" do
      visit project_backlogs_backlog_path(project, all: 1)
      planning_page.expect_no_inbox_show_more
    end
  end
end
