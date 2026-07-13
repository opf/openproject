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

RSpec.describe "User non-working times", :js do
  shared_let(:user) { create(:user, global_permissions: %i[manage_user view_all_principals manage_working_times]) }
  shared_let(:managed_user) { create(:user) }

  let(:nwt_page) { Pages::Users::NonWorkingTimes.new(user: managed_user, year: 2026) }

  current_user { user }

  describe "creating a non-working time" do
    before { nwt_page.visit! }

    it "creates a single-day entry" do
      nwt_page.open_create_dialog

      nwt_page.set_start_date(Date.new(2026, 3, 10))
      nwt_page.set_end_date(Date.new(2026, 3, 10))

      nwt_page.confirm_dialog

      nwt_page.expect_sidebar_entry("Mar 10")
      expect(managed_user.non_working_times.count).to eq(1)
    end

    it "creates a multi-day range and shows correct working day count" do
      nwt_page.open_create_dialog

      # Monday to Friday = 5 working days
      nwt_page.set_start_date(Date.new(2026, 3, 9))
      nwt_page.set_end_date(Date.new(2026, 3, 13))

      nwt_page.confirm_dialog

      nwt_page.expect_sidebar_entry("5 working days")
    end

    it "shows a validation error when end date is before start date" do
      nwt_page.open_create_dialog

      nwt_page.set_start_date(Date.new(2026, 3, 13))
      nwt_page.set_end_date(Date.new(2026, 3, 9))

      within(nwt_page.dialog_selector) { click_on I18n.t(:button_confirm) }

      nwt_page.expect_dialog_open
      nwt_page.expect_validation_error(I18n.t("activerecord.errors.messages.not_before_start_date"))
    end
  end

  describe "editing a non-working time" do
    shared_let(:non_working_time) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 3, 9),
                                     end_date: Date.new(2026, 3, 11))
    end

    before { nwt_page.visit! }

    it "opens the edit dialog when clicking a sidebar entry" do
      nwt_page.open_edit_dialog_from_sidebar

      nwt_page.expect_dialog_dates(start_date: "2026-03-09", end_date: "2026-03-11")
    end

    it "saves updated dates" do
      nwt_page.open_edit_dialog_from_sidebar

      nwt_page.set_end_date(Date.new(2026, 3, 13))
      nwt_page.confirm_dialog

      expect(non_working_time.reload.end_date).to eq(Date.new(2026, 3, 13))
    end
  end

  describe "deleting a non-working time" do
    let!(:non_working_time) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 4, 1),
                                     end_date: Date.new(2026, 4, 3))
    end

    before { nwt_page.visit! }

    it "deletes the entry via the delete button in the edit dialog" do
      nwt_page.open_edit_dialog_from_sidebar
      nwt_page.delete_in_dialog

      expect(UserNonWorkingTime.exists?(non_working_time.id)).to be(false)
    end
  end

  describe "calendar interaction" do
    before { nwt_page.visit! }

    it "pre-fills start and end date when clicking a single calendar day" do
      nwt_page.click_calendar_day("2026-03-10")

      nwt_page.expect_dialog_open
      nwt_page.expect_dialog_dates(start_date: "2026-03-10", end_date: "2026-03-10")
    end

    it "passes the new URL to the calendar so day selection is enabled" do
      nwt_page.expect_selectable_calendar
    end
  end

  describe "calendar interaction - editing from the calendar event" do
    shared_let(:non_working_time) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 3, 9),
                                     end_date: Date.new(2026, 3, 11))
    end

    before { nwt_page.visit! }

    it "opens the edit dialog when clicking a calendar event" do
      nwt_page.open_edit_dialog_from_calendar

      nwt_page.expect_dialog_dates(start_date: "2026-03-09", end_date: "2026-03-11")
    end
  end

  describe "working days count preview" do
    before { nwt_page.visit! }

    it "updates the working days count in real time as dates change" do
      nwt_page.open_create_dialog

      # Monday to Friday = 5 working days
      nwt_page.set_start_date(Date.new(2026, 3, 9))
      nwt_page.set_end_date(Date.new(2026, 3, 13))

      nwt_page.expect_working_days_count(5)
    end
  end

  describe "overlap validation" do
    shared_let(:existing_nwt) do
      create(:user_non_working_time, user: managed_user,
                                     start_date: Date.new(2026, 3, 9),
                                     end_date: Date.new(2026, 3, 15))
    end

    before { nwt_page.visit! }

    it "shows a validation error when the new range overlaps an existing entry" do
      nwt_page.open_create_dialog

      nwt_page.set_start_date(Date.new(2026, 3, 12))
      nwt_page.set_end_date(Date.new(2026, 3, 20))

      within(nwt_page.dialog_selector) { click_on I18n.t(:button_confirm) }

      nwt_page.expect_dialog_open
      nwt_page.expect_validation_error(I18n.t("activerecord.errors.messages.overlapping_range"))
    end
  end

  describe "global non-working days exclusion" do
    shared_let(:holiday) do
      create(:non_working_day, date: Date.new(2026, 3, 11)) # Wednesday
    end

    before { nwt_page.visit! }

    it "excludes system non-working days from the working day count preview" do
      nwt_page.open_create_dialog

      # Mon Mar 9 to Fri Mar 13 would be 5 days, but Wed Mar 11 is a system holiday
      nwt_page.set_start_date(Date.new(2026, 3, 9))
      nwt_page.set_end_date(Date.new(2026, 3, 13))

      nwt_page.expect_working_days_count(4)
    end
  end

  describe "access control" do
    context "with manage_own_working_times permission" do
      current_user { create(:user, global_permissions: [:manage_own_working_times]) }
      let(:nwt_page) { Pages::Users::NonWorkingTimes.new(user: current_user, year: 2026) }

      it "is denied access to their own non-working times on the users page" do
        nwt_page.visit!
        nwt_page.expect_not_authorized
      end

      it "is denied access to another user's non-working times" do
        Pages::Users::NonWorkingTimes.new(user: managed_user, year: 2026).visit!
        nwt_page.expect_not_authorized
      end
    end

    context "with manage_user, view_all_principals, and manage_working_times permissions" do
      current_user { create(:user, global_permissions: %i[manage_user view_all_principals manage_working_times]) }

      shared_let(:other_user_nwt) do
        create(:user_non_working_time, user: managed_user,
                                       start_date: Date.new(2026, 5, 4),
                                       end_date: Date.new(2026, 5, 8))
      end

      before { nwt_page.visit! }

      it "can view another user's non-working times page with the add button" do
        nwt_page.expect_add_button
      end

      it "can open the edit dialog for another user's entry via the sidebar" do
        nwt_page.open_edit_dialog_from_sidebar

        nwt_page.expect_dialog_start_date("2026-05-04")
        nwt_page.expect_dialog_has_delete_button
      end

      it "can create a new entry for another user" do
        nwt_page.open_create_dialog

        nwt_page.set_start_date(Date.new(2026, 6, 1))
        nwt_page.set_end_date(Date.new(2026, 6, 5))

        nwt_page.confirm_dialog

        expect(managed_user.non_working_times.count).to eq(2)
      end
    end

    context "with no working times permissions" do
      current_user { create(:user) }

      it "is denied access" do
        nwt_page.visit!
        nwt_page.expect_not_authorized
      end
    end
  end
end
