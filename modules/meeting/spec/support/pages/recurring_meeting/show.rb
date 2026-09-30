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

require_relative "../meetings/base"

module Pages::RecurringMeeting
  class Show < ::Pages::Meetings::Base
    attr_accessor :meeting

    def initialize(meeting)
      super(meeting.project)

      self.meeting = meeting
    end

    def path
      project_recurring_meeting_path(project, meeting)
    end

    def expect_planned_meeting(date:)
      within_row(date) do
        expect(page).to have_css(".status", text: "Planned")
      end
    end

    def expect_no_planned_meeting(date:)
      within_row(date) do
        expect(page).to have_no_css(".status", text: "Planned")
      end
    end

    def expect_open_meeting(date:)
      within_row(date) do
        expect(page).to have_css(".status", text: "Open")
      end
    end

    def expect_no_open_meeting(date:)
      within_row(date) do
        expect(page).to have_no_css(".status", text: "Open")
      end
    end

    def expect_cancelled_meeting(date:)
      within_row(date) do
        expect(page).to have_css(".status", text: "Cancelled")
      end
    end

    def expect_no_cancelled_meeting(date:)
      within_row(date) do
        expect(page).to have_no_css(".status", text: "Cancelled")
      end
    end

    def expect_rescheduled_meeting(old_date:, new_date:)
      within_row(old_date) do
        expect(page).to have_css("s", text: old_date)
        expect(page).to have_text("#{old_date}\n#{new_date}")
      end
    end

    def open(date:)
      within_row(date) do
        click_on "Open"
      end
    end

    def restore(date:)
      within_row(date) do
        click_on "more-button"
        click_on "Restore this occurrence"
      end
    end

    def cancel_occurrence(date:)
      within_row(date) do
        click_on "more-button"
        click_on "Cancel this occurrence"
      end

      expect_modal("Cancel meeting occurrence")
    end

    def expect_subtitle(text:)
      expect(page).to have_css(".PageHeader-description", text: text)
    end

    def edit_meeting_series
      page.find_test_selector("recurring-meeting-action-menu").click
      click_on "Edit meeting series"

      expect_modal("Edit Meeting")
    end

    def delete_meeting_series
      page.find_test_selector("recurring-meeting-action-menu").click
      click_on "Delete meeting series"

      expect_modal("Delete meeting series")
    end

    def end_meeting_series
      page.find_test_selector("recurring-meeting-action-menu").click
      click_on "End meeting series"

      expect_modal("End meeting series")
    end

    def expect_modal(...)
      Components::Common::Modal.new.expect_modal(...)
    end

    def expect_no_meeting(date:)
      expect(page).to have_no_row(date)
    end

    def expect_no_actions(date:)
      within_row(date) do
        expect(page).not_to have_test_selector("more-button")
      end
    end

    def expect_open_actions(date:)
      within_row(date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 2)
        expect(page).to have_css(".ActionListItem-label", text: "Download iCalendar event")
        expect(page).to have_css(".ActionListItem-label", text: "Cancel this occurrence")

        # Close it again
        click_on "more-button"
      end
    end

    def expect_planned_actions(date:)
      within_row(date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 2)
        expect(page).to have_css(".ActionListItem-label", text: "Open")
        expect(page).to have_css(".ActionListItem-label", text: "Cancel this occurrence")

        # Close it again
        click_on "more-button"
      end
    end

    def expect_cancelled_actions(date:)
      within_row(date) do
        click_on "more-button"

        expect(page).to have_css(".ActionListItem-label", count: 1)
        expect(page).to have_css(".ActionListItem-label", text: "Restore this occurrence")

        # Close it again
        click_on "more-button"
      end
    end
  end
end
