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

require "rbconfig"
require "support/pages/page"

module Pages
  class MeetingsTab < Page
    attr_reader :work_package_id

    def initialize(work_package_id)
      super()
      @work_package_id = work_package_id
    end

    def path
      "/work_packages/#{work_package_id}/tabs/meetings"
    end

    def expect_tab_present
      expect(page).to have_css(".op-tab-row--link", text: "MEETINGS")
    end

    def expect_tab_count(count)
      expect(page).to have_css(".op-tab-row--link", text: "MEETINGS (#{count})", wait: 10)
    end

    def expect_tab_not_present
      expect(page).to have_no_css(".op-tab-row--link", text: "MEETINGS")
    end

    def expect_tab_content_rendered
      expect(page).to have_test_selector("op-work-package-meetings-tab-container")
    end

    def expect_upcoming_counter_to_be(amount)
      page.within_test_selector("op-upcoming-meetings-counter") do
        expect(page).to have_content(amount)
      end
    end

    def expect_past_counter_to_be(amount)
      page.within_test_selector("op-past-meetings-counter") do
        expect(page).to have_content(amount)
      end
    end

    def expect_add_to_meeting_button_present
      expect(page).to have_test_selector("op-add-work-package-to-meeting-dialog-trigger")
    end

    def expect_add_to_meeting_button_not_present
      expect(page).not_to have_test_selector("op-add-work-package-to-meeting-dialog-trigger")
    end

    def expect_add_to_meeting_dialog_shown
      expect(page).to have_css("#add-work-package-to-meeting-dialog")
    end

    def switch_to_upcoming_meetings_section
      within container_element do
        find(".tabnav-tab", text: "Upcoming").click
      end
    end

    def switch_to_past_meetings_section
      within container_element do
        find(".tabnav-tab", text: "Past").click
      end
    end

    def open_add_to_meeting_dialog
      page.find_test_selector("op-add-work-package-to-meeting-dialog-trigger").click
    end

    def fill_and_submit_meeting_dialog(meeting, notes)
      fill_in("meeting_agenda_item_meeting_id", with: meeting.title)
      expect(page).to have_css(".ng-option-marked", text: meeting.title) # wait for selection
      page.find(".ng-option-marked").click
      page.find(".ck-editor__editable").set(notes)

      click_on("Save")
    end

    private

    def container_element
      page.find_test_selector("op-work-package-meetings-tab-container")
    end

    def osx?
      RbConfig::CONFIG["host_os"].include?("darwin")
    end
  end
end
