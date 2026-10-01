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

RSpec.describe "User working hours", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:managed_user) { create(:user) }

  let(:wh_page) { Pages::Users::WorkingHours.new(user: managed_user) }

  current_user { admin }

  describe "current schedule card" do
    context "when no working hours exist" do
      before { wh_page.visit! }

      it "shows the not-set placeholder text in the stats" do
        wh_page.expect_current_schedule_section
        wh_page.expect_not_set
      end

      it "shows the edit pencil linked to the create dialog" do
        wh_page.expect_editable_current_schedule
      end
    end

    context "when working hours are set for today" do
      shared_let(:working_hours) do
        create(:user_working_hours,
               user: managed_user,
               valid_from: Date.current,
               monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
               saturday: 0, sunday: 0,
               availability_factor: 80)
      end

      before { wh_page.visit! }

      it "displays the correct work days, hours, availability, and effective hours" do
        wh_page.expect_stats(
          work_days: 5,
          weekly_hours: "40h",
          availability: "80%",
          effective_hours: "32h"
        )
      end

      it "shows the pencil linked to the edit dialog" do
        wh_page.open_current_schedule_dialog

        wh_page.expect_dialog_title_current
      end
    end
  end

  describe "creating a current schedule" do
    before { wh_page.visit! }

    it "creates working hours via the current schedule dialog" do
      wh_page.open_current_schedule_dialog

      wh_page.expect_dialog_title_current
      wh_page.expect_no_valid_from_field

      wh_page.submit_dialog

      expect(managed_user.working_hours.count).to eq(1)
      expect(managed_user.working_hours.current.valid_from).to eq(Date.current)
    end
  end

  describe "editing the current schedule" do
    shared_let(:working_hours) do
      create(:user_working_hours,
             user: managed_user,
             valid_from: Date.current,
             monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
             saturday: 0, sunday: 0,
             availability_factor: 100)
    end

    before { wh_page.visit! }

    it "opens the edit dialog with the current schedule's title" do
      wh_page.open_current_schedule_dialog

      wh_page.expect_dialog_title_current
      wh_page.expect_no_valid_from_field
    end

    it "saves changes to the current schedule" do
      wh_page.open_current_schedule_dialog
      wh_page.set_availability_factor(75)
      wh_page.save_dialog

      expect(working_hours.reload.availability_factor).to eq(75)
    end
  end

  describe "future schedules" do
    describe "adding a future schedule" do
      before { wh_page.visit! }

      it "shows the future schedule section with an add button" do
        wh_page.expect_future_section
        wh_page.expect_add_future_button
      end

      it "shows the blank slate when no future schedules exist" do
        wh_page.expect_future_blank_slate
      end

      it "creates a future schedule via the dialog" do
        wh_page.open_add_future_schedule_dialog

        wh_page.expect_dialog_title_future
        wh_page.expect_valid_from_field

        wh_page.set_valid_from(Date.new(2027, 1, 1))

        wh_page.submit_dialog

        expect(managed_user.working_hours.upcoming(Date.new(2027, 1, 1)).count).to eq(1)
      end
    end

    describe "editing a future schedule" do
      shared_let(:future_wh) do
        create(:user_working_hours,
               user: managed_user,
               valid_from: Date.new(2027, 6, 1),
               monday: 240, tuesday: 240, wednesday: 240, thursday: 240, friday: 240,
               saturday: 0, sunday: 0,
               availability_factor: 100)
      end

      before { wh_page.visit! }

      it "opens the edit dialog from the action menu" do
        wh_page.open_row_action_menu
        click_on I18n.t(:button_edit)

        expect(page).to have_css(wh_page.dialog_selector)
        wh_page.expect_dialog_title_future
      end

      it "saves updated values" do
        wh_page.open_row_action_menu
        click_on I18n.t(:button_edit)

        wh_page.set_availability_factor(50)
        wh_page.save_dialog

        expect(future_wh.reload.availability_factor).to eq(50)
      end
    end

    describe "deleting a future schedule" do
      it "deletes the schedule via the action menu" do
        future_wh = create(:user_working_hours,
                           user: managed_user,
                           valid_from: Date.new(2027, 6, 1),
                           monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
                           saturday: 0, sunday: 0,
                           availability_factor: 100)

        wh_page.visit!

        wh_page.open_row_action_menu
        wh_page.delete_schedule

        expect(UserWorkingHours.exists?(future_wh.id)).to be(false)
      end
    end
  end

  describe "schedule history" do
    shared_let(:past_wh) do
      create(:user_working_hours,
             user: managed_user,
             valid_from: Date.new(2025, 1, 1),
             monday: 360, tuesday: 360, wednesday: 360, thursday: 360, friday: 360,
             saturday: 0, sunday: 0,
             availability_factor: 100)
    end

    shared_let(:current_wh) do
      create(:user_working_hours,
             user: managed_user,
             valid_from: Date.new(2026, 1, 1),
             monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
             saturday: 0, sunday: 0,
             availability_factor: 100)
    end

    before { wh_page.visit! }

    it "shows past schedules in the history section" do
      wh_page.expect_history_section
      # The 2025 entry has 6h/day × 5 days = 30h/week
      expect(page).to have_text("30h")
    end
  end

  describe "access control" do
    context "with manage_own_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_own_working_times]) }
      let(:wh_page) { Pages::Users::WorkingHours.new(user: current_user) }

      it "is denied access to their own working hours on the users page" do
        wh_page.visit!
        wh_page.expect_not_authorized
      end

      it "is denied access to another user's working hours" do
        Pages::Users::WorkingHours.new(user: managed_user).visit!
        wh_page.expect_not_authorized
      end
    end

    context "with manage_user, view_all_principals, and manage_working_times permissions" do
      current_user { create(:user, global_permissions: %i[manage_user view_all_principals manage_working_times]) }

      it "can view another user's working hours page" do
        wh_page.visit!

        wh_page.expect_current_schedule_section
        wh_page.expect_editable_current_schedule
      end
    end

    context "with no working times permissions" do
      current_user { create(:user) }

      it "is denied access" do
        wh_page.visit!
        wh_page.expect_not_authorized
      end
    end
  end
end
