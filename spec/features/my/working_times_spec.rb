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

RSpec.describe "My working times pages", :js do
  describe "/my/non_working_times" do
    let(:nwt_page) { Pages::Users::NonWorkingTimes.new(year: 2026) }

    context "with manage_own_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_own_working_times]) }

      it "renders the calendar for the current user" do
        nwt_page.visit!

        nwt_page.expect_calendar_rendered
      end

      it "makes the calendar selectable (new URL data attribute is present)" do
        nwt_page.visit!

        nwt_page.expect_selectable_calendar
      end

      it "shows the add button" do
        nwt_page.visit!

        nwt_page.expect_add_button
      end

      context "when clicking a calendar day" do
        it "opens the create dialog pre-filled with that date" do
          nwt_page.visit!

          nwt_page.click_calendar_day("2026-04-14")

          nwt_page.expect_dialog_open
          nwt_page.expect_dialog_dates(start_date: "2026-04-14", end_date: "2026-04-14")
        end
      end

      context "when creating a non-working time" do
        it "can create an entry for themselves" do
          nwt_page.visit!

          nwt_page.open_create_dialog

          nwt_page.set_start_date(Date.new(2026, 7, 6))
          nwt_page.set_end_date(Date.new(2026, 7, 10))

          nwt_page.confirm_dialog

          expect(current_user.non_working_times.count).to eq(1)
        end
      end

      context "when editing an existing entry" do
        let!(:nwt) do
          create(:user_non_working_time, user: current_user,
                                         start_date: Date.new(2026, 8, 3),
                                         end_date: Date.new(2026, 8, 7))
        end

        it "can edit via the sidebar link" do
          nwt_page.visit!

          nwt_page.open_edit_dialog_from_sidebar
          nwt_page.expect_dialog_start_date("2026-08-03")
        end
      end
    end

    context "with manage_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_working_times]) }

      it "renders the calendar with the add button and selectable calendar" do
        nwt_page.visit!

        nwt_page.expect_add_button
        nwt_page.expect_selectable_calendar
      end
    end

    context "with no working times permissions" do
      current_user { create(:user) }

      it "renders the page but without the add button or selectable calendar" do
        nwt_page.visit!

        nwt_page.expect_calendar_rendered
        nwt_page.expect_no_add_button
        nwt_page.expect_non_selectable_calendar
      end
    end
  end

  describe "/my/working_hours" do
    let(:wh_page) { Pages::Users::WorkingHours.new }

    context "with manage_own_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_own_working_times]) }

      it "renders the current schedule section" do
        wh_page.visit!

        wh_page.expect_current_schedule_section
        wh_page.expect_future_section
        wh_page.expect_history_section
      end

      it "shows the pencil button to manage the current schedule" do
        wh_page.visit!

        wh_page.expect_editable_current_schedule
      end

      it "shows the add button for future schedules" do
        wh_page.visit!

        wh_page.expect_add_future_button
      end

      context "when creating a current schedule" do
        it "opens the dialog without a valid_from field and creates the record" do
          wh_page.visit!

          wh_page.open_current_schedule_dialog
          wh_page.expect_dialog_title_current
          wh_page.expect_no_valid_from_field

          wh_page.submit_dialog

          expect(current_user.working_hours.current).to be_present
        end
      end

      context "with an existing current schedule" do
        let!(:working_hours) do
          create(:user_working_hours,
                 user: current_user,
                 valid_from: Date.current,
                 monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
                 saturday: 0, sunday: 0,
                 availability_factor: 100)
        end

        it "shows the correct stats on the current schedule card" do
          wh_page.visit!

          wh_page.expect_stats(work_days: 5, weekly_hours: "40h", availability: "100%")
        end

        it "opens the edit dialog for the current schedule" do
          wh_page.visit!

          wh_page.open_current_schedule_dialog
          wh_page.expect_dialog_title_current
        end
      end
    end

    context "with manage_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_working_times]) }

      it "renders the working hours page" do
        wh_page.visit!

        wh_page.expect_current_schedule_section
      end
    end

    context "with no working times permissions" do
      current_user { create(:user) }

      it "renders the page but without the edit pencil enabled" do
        wh_page.visit!

        wh_page.expect_current_schedule_section
        wh_page.expect_not_editable_current_schedule
      end
    end
  end
end
