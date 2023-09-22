#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'rbconfig'
require 'support/pages/page'

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

    def expect_tab_not_present
      expect(page).not_to have_selector('.op-tab-row--link', text: 'MEETINGS')
    end

    def expect_tab_content_rendered
      expect(page).to have_test_selector('op-work-package-meetings-tab-container')
    end

    def expect_upcoming_counter_to_be(amount)
      within_test_selector('op-upcoming-meetings-counter') do
        expect(page).to have_content(amount)
      end
    end

    def expect_past_counter_to_be(amount)
      within_test_selector('op-past-meetings-counter') do
        expect(page).to have_content(amount)
      end
    end

    def expect_add_to_meeting_button_present
      expect(page).to have_test_selector('op-add-work-package-to-meeting-dialog-trigger')
    end

    def expect_add_to_meeting_button_not_present
      # wait for the tab content to be rendered asynchronously before proceeding with expectations
      # otherwise might get false positives as the element not present due to a shown loading state
      expect_tab_content_rendered

      expect(page).not_to have_test_selector('op-add-work-package-to-meeting-dialog-trigger')
    end

    def expect_add_to_meeting_dialog_shown
      expect(page).to have_test_selector('op-add-work-package-to-meeting-dialog-body')
    end

    def switch_to_upcoming_meetings_section
      within container_element do
        find('.tabnav-tab', text: 'Upcoming').click
      end
    end

    def switch_to_past_meetings_section
      within container_element do
        find('.tabnav-tab', text: 'Past').click
      end
    end

    def open_add_to_meeting_dialog
      # wait for the tab content to be rendered asynchronously before proceeding
      expect_tab_content_rendered

      page.find_test_selector('op-add-work-package-to-meeting-dialog-trigger').click
    end

    private

    def container_element
      page.find_test_selector('op-work-package-meetings-tab-container')
    end

    def osx?
      RbConfig::CONFIG['host_os'].include?('darwin')
    end
  end
end
