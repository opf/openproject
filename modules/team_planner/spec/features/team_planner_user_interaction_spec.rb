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

RSpec.describe "Team planner drag&dop and resizing",
               :js,
               with_ee: %i[team_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with team planner full access"

  let!(:other_user) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[view_work_packages view_team_planner work_package_assigned] })
  end

  let!(:first_wp) do
    create(:work_package,
           project:,
           assigned_to: other_user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end
  let!(:second_wp) do
    create(:work_package,
           project:,
           parent: first_wp,
           assigned_to: other_user,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:thursday))
  end
  let!(:third_wp) do
    create(:work_package,
           project:,
           assigned_to: user,
           start_date: Time.zone.today - 10.days,
           due_date: Time.zone.today + 20.days)
  end

  let(:milestone_type) { create(:type, is_milestone: true) }
  let!(:fourth_wp) do
    create(:work_package,
           project:,
           assigned_to: user,
           type: milestone_type,
           start_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday),
           due_date: Time.zone.today.beginning_of_week.next_occurring(:tuesday))
  end

  context "with full permissions" do
    before do
      team_planner.visit!

      team_planner.add_assignee user
      team_planner.add_assignee other_user

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp, present: false
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp
        team_planner.expect_event fourth_wp
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp
        team_planner.expect_event third_wp, present: false
        team_planner.expect_event fourth_wp, present: false
      end
    end

    it "allows to drag&drop between the lanes to change the assignee" do
      # Move first wp to the user
      retry_block do
        team_planner.drag_wp_to_lane(first_wp, user)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp
        team_planner.expect_event fourth_wp
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event first_wp, present: false
        team_planner.expect_event second_wp
        team_planner.expect_event third_wp, present: false
        team_planner.expect_event fourth_wp, present: false
      end

      # Move second wp to the user, resulting in the other user having no WPs any more
      retry_block do
        team_planner.drag_wp_to_lane(second_wp, user)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp
        team_planner.expect_event third_wp
        team_planner.expect_event fourth_wp
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event first_wp, present: false
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp, present: false
        team_planner.expect_event fourth_wp, present: false
      end

      # Move the third WP to the empty row of the other user
      retry_block do
        team_planner.drag_wp_to_lane(third_wp, other_user)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp
        team_planner.expect_event third_wp, present: false
        team_planner.expect_event fourth_wp
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event first_wp, present: false
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp
        team_planner.expect_event fourth_wp, present: false
      end

      # Move the Milestone
      retry_block do
        team_planner.drag_wp_to_lane(fourth_wp, other_user)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      team_planner.within_lane(user) do
        team_planner.expect_event first_wp
        team_planner.expect_event second_wp
        team_planner.expect_event third_wp, present: false
        team_planner.expect_event fourth_wp, present: false
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event first_wp, present: false
        team_planner.expect_event second_wp, present: false
        team_planner.expect_event third_wp
        team_planner.expect_event fourth_wp
      end
    end

    it "allows to resize to change the dates of a wp" do
      retry_block do
        # Change date of second_wp by resizing it
        team_planner.change_wp_date_by_resizing(second_wp, number_of_days: 1, is_start_date: true)
      end

      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      # The date has changed, but the assignee remains unchanged.
      # Because of the hierarchy, the first wp is updated, too.
      first_wp.reload
      second_wp.reload
      expect(second_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))
      expect(second_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:thursday))
      expect(second_wp.assigned_to_id).to eq(other_user.id)

      expect(first_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))
      expect(first_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:thursday))

      # The calendar needs some time to redraw. If we continue right away we'd get conflicting modifications
      sleep 5

      # Change the dates by dragging the complete wp
      retry_block do
        team_planner.drag_wp_by_pixel(second_wp, -150, 0)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      first_wp.reload
      second_wp.reload
      expect(second_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:tuesday))
      expect(second_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))
      expect(second_wp.assigned_to_id).to eq(other_user.id)

      expect(second_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:tuesday))
      expect(second_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))

      # The calendar needs some time to redraw. If we continue right away we'd get conflicting modifications
      sleep 5

      # Parent elements cannot be resized, as they derive their values from their children
      team_planner.expect_wp_not_resizable(first_wp)
      # Elements that have start or due date outside of the current view are also not resizable
      team_planner.expect_wp_not_resizable(third_wp)
      # Milestones are not resizable
      team_planner.expect_wp_not_resizable(fourth_wp)

      # Instead we move the milestone completely to change the date
      retry_block do
        team_planner.drag_wp_by_pixel(fourth_wp, 150, 0)
      end
      team_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      fourth_wp.reload
      expect(fourth_wp.start_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))
      expect(fourth_wp.due_date).to eq(Time.zone.today.beginning_of_week.next_occurring(:wednesday))
      expect(fourth_wp.assigned_to_id).to eq(user.id)
    end
  end

  context "without permission to edit" do
    current_user { other_user }

    before do
      team_planner.visit!

      team_planner.add_assignee user
      team_planner.add_assignee other_user
    end

    it "allows neither dragging nor resizing any wp" do
      team_planner.expect_wp_not_resizable(first_wp)
      team_planner.expect_wp_not_resizable(second_wp)
      team_planner.expect_wp_not_resizable(third_wp)
      team_planner.expect_wp_not_resizable(fourth_wp)

      team_planner.expect_wp_not_draggable(first_wp)
      team_planner.expect_wp_not_draggable(second_wp)
      team_planner.expect_wp_not_draggable(third_wp)
      team_planner.expect_wp_not_draggable(fourth_wp)
    end
  end
end
