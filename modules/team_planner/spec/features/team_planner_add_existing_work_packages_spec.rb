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
require_relative "shared_context"
require_relative "../support/components/add_existing_pane"

RSpec.describe "Team planner add existing work packages", :js do
  include_context "with team planner full access"

  let(:closed_status) { create(:status, is_closed: true) }
  let(:start_of_week) { Time.zone.today.beginning_of_week(:sunday) }

  let!(:other_user) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[view_work_packages view_team_planner] })
  end

  let!(:first_wp) do
    create(:work_package,
           project:,
           subject: "Task 1",
           assigned_to: user,
           start_date: start_of_week.next_occurring(:tuesday),
           due_date: start_of_week.next_occurring(:thursday))
  end
  let!(:second_wp) do
    create(:work_package,
           project:,
           subject: "Task 2",
           parent: first_wp,
           assigned_to: other_user,
           start_date: 10.days.from_now,
           due_date: 12.days.from_now)
  end
  let!(:third_wp) do
    create(:work_package,
           project:,
           subject: "TA Aufgabe 3",
           status: closed_status)
  end

  let(:add_existing_pane) { Components::AddExistingPane.new }
  let(:filters) { Components::WorkPackages::Filters.new }

  context "with full permissions", with_ee: %i[team_planner_view] do
    before do
      team_planner.visit!

      team_planner.add_assignee user

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp, present: false
      end

      # Open the left hand pane
      add_existing_pane.open
      add_existing_pane.expect_empty
    end

    context "with a removable item" do
      let!(:second_wp) do
        create(:work_package,
               project:,
               subject: "Task 2",
               assigned_to: other_user,
               start_date: 10.days.from_now,
               due_date: 12.days.from_now)
      end

      it "shows work packages removed from the team planner" do
        team_planner.within_lane(user) do
          team_planner.expect_event first_wp
        end

        add_existing_pane.search first_wp.subject
        add_existing_pane.expect_empty

        # Remove task 1 from the team planner
        team_planner.drag_to_remove_dropzone first_wp, expect_removable: true

        sleep 2

        add_existing_pane.expect_result first_wp
      end
    end

    it "allows to click cards to open split view when open" do
      # Search for a work package
      add_existing_pane.search "Task"
      add_existing_pane.expect_result second_wp

      # Open first wp
      split_screen = team_planner.open_split_view_by_info_icon first_wp
      split_screen.expect_subject
      expect(page).to have_current_path /\/details\/#{first_wp.id}/

      # Select work package in add existing
      add_existing_pane.card(second_wp).click
      split_screen = Pages::SplitWorkPackage.new second_wp
      split_screen.expect_subject
      expect(page).to have_current_path /\/details\/#{second_wp.id}/
    end

    it "allows to add work packages via drag&drop from the left hand shortlist" do
      # Search for a work package
      add_existing_pane.search "Task"
      add_existing_pane.expect_result second_wp

      sleep 2

      # Drag it to the team planner...
      add_existing_pane.drag_wp_by_pixel second_wp, 800, 0

      team_planner.expect_and_dismiss_toaster(message: "Successful update.")

      # ... and thus update its attributes. Thereby the duration is maintained
      second_wp.reload
      expect(second_wp.start_date).to eq(start_of_week.next_occurring(:tuesday))
      expect(second_wp.due_date).to eq(start_of_week.next_occurring(:thursday))
      expect(second_wp.assigned_to_id).to eq(user.id)

      # Search for another work package
      add_existing_pane.search "Ta"
      add_existing_pane.expect_result third_wp

      sleep 2

      # Drag it to the team planner...
      add_existing_pane.drag_wp_by_pixel third_wp, 800, 100

      team_planner.expect_and_dismiss_toaster(message: "Successful update.")

      # ... and thus update its attributes. Since no dates were set before, start and end date are set to the same day
      third_wp.reload
      expect(third_wp.start_date).to eq(start_of_week.next_occurring(:tuesday))
      expect(third_wp.due_date).to eq(start_of_week.next_occurring(:tuesday))
      expect(third_wp.assigned_to_id).to eq(user.id)

      # New events are directly clickable
      split_view = team_planner.open_split_view_by_info_icon(third_wp)
      split_view.expect_open
    end

    it "the search applies the filter from the team planner" do
      # Search for a work package
      add_existing_pane.search "Task"
      add_existing_pane.expect_result second_wp
      add_existing_pane.expect_result third_wp, visible: false

      # WP that are already shown in the team planner are not shown again
      add_existing_pane.expect_result first_wp, visible: false

      filters.expect_filter_count 1
      filters.open
      filters.expect_filter_by "Status", "is not empty", nil

      # Change the filter for the whole page
      filters.set_filter "Status", "open", nil

      # Expect the filter to auto update
      add_existing_pane.expect_result second_wp
      add_existing_pane.expect_result third_wp, visible: false
    end

    context "with a subproject" do
      let!(:sub_project) do
        create(:project, name: "Child", parent: project, enabled_module_names: %w[work_package_tracking])
      end

      let!(:sub_work_package) do
        create(:work_package, subject: "Subtask", project: sub_project)
      end

      let(:permissions) do
        %w[
          view_work_packages edit_work_packages add_work_packages
          view_team_planner manage_team_planner
          save_queries manage_public_queries
        ]
      end

      let!(:user) do
        create(:user, member_with_permissions: { project => permissions, sub_project => permissions })
      end

      let(:dropdown) { Components::ProjectIncludeComponent.new }

      it "applies the project include filter" do
        # Search for the work package in the child project
        add_existing_pane.search "Subtask"
        add_existing_pane.expect_empty
        add_existing_pane.expect_result sub_work_package, visible: false

        dropdown.expect_count 1
        dropdown.toggle!
        dropdown.expect_open

        dropdown.toggle_include_all_subprojects

        dropdown.expect_checkbox(project.id, true)
        dropdown.expect_checkbox(sub_project.id, false)

        dropdown.click_button "Apply"
        dropdown.expect_closed
        dropdown.expect_count 1
        dropdown.toggle!
        dropdown.expect_open

        dropdown.toggle_checkbox(sub_project.id)

        dropdown.expect_checkbox(project.id, true)
        dropdown.expect_checkbox(sub_project.id, true)

        dropdown.click_button "Apply"
        dropdown.expect_closed
        dropdown.expect_count 2

        # Expect the filter to auto update
        add_existing_pane.expect_result sub_work_package
      end
    end
  end

  context "without permission to edit" do
    current_user { other_user }

    before do
      team_planner.visit!
    end

    it "does not show the button to add existing work packages" do
      expect(page).not_to have_test_selector("op-team-planner--add-existing-toggle")
      add_existing_pane.expect_closed
    end
  end
end
