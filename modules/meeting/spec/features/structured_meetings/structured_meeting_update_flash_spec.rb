#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require_relative "../../support/pages/meetings/new"
require_relative "../../support/pages/structured_meeting/show"

RSpec.describe "Structured meetings CRUD",
               :js,
               with_cuprite: false do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) { create(:admin) }

  current_user { user }
  let(:new_page) { Pages::Meetings::New.new(project) }
  let(:meeting) { create(:structured_meeting, project:, author: current_user) }
  let(:show_page) { Pages::StructuredMeeting::Show.new(meeting) }

  describe "meeting update flash", with_flag: { meeting_updated_notification: true } do
    before do
      # Disable the polling so we can trigger it manually
      allow_any_instance_of(Meetings::HeaderComponent) # rubocop:disable RSpec/AnyInstance
        .to receive(:check_for_updates_interval)
              .and_return(0)
    end

    it do
      flash_component = ".op-toast--wrapper"

      ## Add agenda item
      show_page.visit!

      first_window = current_window
      second_window = open_new_window

      within_window(second_window) do
        show_page.visit!

        show_page.add_agenda_item do
          fill_in "Title", with: "Update toast test item"
        end
      end

      # Expect notification in window1
      within_window(first_window) do
        show_page.trigger_change_poll
        expect(page).to have_css(flash_component, wait: 5)
        expect(page).to have_text I18n.t(:notice_meeting_updated)
        page.within(".flash") { click_on "Reload" }
      end

      # Expect no notification in window2
      within_window(second_window) do
        show_page.trigger_change_poll
        expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      end

      ## Edit agenda item
      within_window(first_window) do
        item = MeetingAgendaItem.find_by(title: "Update toast test item")

        show_page.edit_agenda_item(item) do
          fill_in "Title", with: "Updated title"
          click_on "Save"
        end

        # Expect no notification in window1
        show_page.trigger_change_poll
        expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      end

      # Expect notification in window2
      within_window(second_window) do
        show_page.trigger_change_poll
        expect(page).to have_css(flash_component, wait: 5)
        expect(page).to have_text I18n.t(:notice_meeting_updated)

        page.within(".flash") { click_on "Reload" }

        ## Add section
        show_page.add_section do
          fill_in "Title", with: "First section"
          click_on "Save"
        end

        show_page.expect_section(title: "First section")
      end

      # Expect notification in window1
      within_window(first_window) do
        show_page.trigger_change_poll
        expect(page).to have_css(flash_component, wait: 5)
        expect(page).to have_text I18n.t(:notice_meeting_updated)
        page.within(".flash") { click_on "Reload" }
      end

      # Expect no notification in window2
      within_window(second_window) do
        show_page.trigger_change_poll
        expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      end

      ## Edit meeting details
      within_window(first_window) do
        find_test_selector("edit-meeting-details-button").click
        fill_in "structured_meeting_duration", with: "2.5"
        click_link_or_button "Save"

        # Expect updated duration
        expect(page).to have_text "2 hrs, 30 mins"

        # Expect no notification in window1
        show_page.trigger_change_poll
        expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      end

      # Expect notification in window2
      within_window(second_window) do
        show_page.trigger_change_poll
        expect(page).to have_text I18n.t(:notice_meeting_updated)

        page.within(".flash") { click_on "Reload" }

        ## Close meeting
        find_test_selector("close-meeting-button").click
      end

      # Expect notification in window1
      within_window(first_window) do
        show_page.trigger_change_poll
        expect(page).to have_css(flash_component, wait: 5)
        expect(page).to have_text I18n.t(:notice_meeting_updated)
        page.within(".flash") { click_on "Reload" }
      end

      # Expect no notification in window2
      within_window(second_window) do
        show_page.trigger_change_poll
        expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      end

      second_window.close
    end
  end
end
