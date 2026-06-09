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

module Pages::Meetings
  class Index < Pages::Page
    include Components::Common::Filters
    include Components::Autocompleter::NgSelectAutocompleteHelpers

    attr_accessor :project

    def initialize(project:)
      super()

      self.project = project
    end

    def set_title(text)
      fill_in "Title", with: text
    end

    def set_start_date(date)
      fill_in "Date", with: date
    end

    def set_starts_on(date)
      fill_in "Starts on", with: date
    end

    def set_start_time(time)
      input = page.find_by_id("meeting_start_time_hour")
      page.execute_script("arguments[0].value = arguments[1]", input.native, time)
      page.execute_script("arguments[0].dispatchEvent(new Event('input'))", input.native)
    end

    def set_end_after(value)
      select value, from: "Meeting series ends"
    end

    def set_end_date(date)
      fill_in "End date", with: date, fill_options: { clear: :backspace }
    end

    def set_project(project)
      select_autocomplete find("[data-test-selector='project_id']"),
                          query: project.name,
                          results_selector: "body"
    end

    def set_duration(duration)
      fill_in "Duration", with: duration
    end

    def click_create
      within "#new-meeting-dialog" do
        click_on "Create meeting"
      end
      wait_for_network_idle
    end

    def expect_no_main_menu
      expect(page).to have_no_css "#main-menu"
    end

    def expect_no_create_new_button
      expect(page).not_to have_test_selector("add-meeting-button")
    end

    def expect_create_new_button
      expect(page).to have_test_selector("add-meeting-button")
    end

    def expect_create_new_types
      click_on("add-meeting-button")

      expect(page).to have_link("Recurring")
      expect(page).to have_link("One-time")
    end

    def expect_copy_action(meeting)
      within more_menu(meeting) do
        expect(page).to have_link("Duplicate meeting")
      end
    end

    def expect_no_copy_action(meeting)
      within more_menu(meeting) do
        expect(page).to have_no_link("Duplicate meeting")
      end
    end

    def expect_delete_action(meeting)
      within more_menu(meeting) do
        expect(page).to have_link("Delete meeting")
      end
    end

    def expect_no_delete_action(meeting)
      within more_menu(meeting) do
        expect(page).to have_no_button("Delete meeting")
      end
    end

    def expect_ical_action(meeting)
      within more_menu(meeting) do
        expect(page).to have_link("Download iCalendar event")
      end
    end

    def set_sidebar_filter(filter_name)
      submenu.click_item(filter_name)
    end

    def set_quick_filter(upcoming: true)
      page.within("#content-body") do
        if upcoming
          click_link_or_button "Upcoming"
        else
          click_link_or_button "Past"
        end
      end

      wait_for_network_idle
    end

    def set_project_filter(*projects)
      find_test_selector("quick-filter-select-panel-button").click

      projects.each do |project|
        option = find("[role='option']", text: project.name)
        option.click unless option[:"aria-selected"] == "true"
      end

      within("[data-controller='quick-filter--select-panel']") do
        click_link_or_button I18n.t(:button_apply)
      end

      wait_for_network_idle
    end

    def expect_no_meetings_listed
      within "#content-wrapper" do
        expect(page)
          .to have_content I18n.t("meeting.blankslate.title")
      end
    end

    def expect_blank_slate_component
      expect(page).to have_test_selector("meetings-blank-slate")
    end

    def expect_meetings_listed_in_order(*meetings)
      retry_block do
        listed_meeting_titles = all(:role, :rowheader).map(&:text)
        expect(listed_meeting_titles).to eq(meetings.map(&:title))
      end
    end

    def expect_meetings_listed_in_table(*meetings)
      within "[data-test-selector='Meetings::TableComponent']" do
        meetings.each do |meeting|
          expect(page).to have_role(:rowheader, text: meeting.title)
        end
      end
    end

    def expect_meeting_listed_in_group(meeting, key: meeting_group_key(meeting))
      within "[data-test-selector='meetings-table-#{key}']" do
        expect(page).to have_role(:rowheader, text: meeting.title)
      end
    end

    def meeting_group_key(meeting)
      start_date = meeting.start_time.to_date
      next_week = Time.current.next_occurring(OpenProject::Internationalization::Date.beginning_of_week).beginning_of_day

      if start_date == Time.zone.today
        :today
      elsif start_date == Time.zone.tomorrow
        :tomorrow
      elsif start_date < next_week
        :this_week
      else
        :later
      end
    end

    def expect_meetings_listed(*meetings)
      meetings.each do |meeting|
        expect(page).to have_role(:rowheader, text: meeting.title)
      end
    end

    def expect_meetings_not_listed(*meetings)
      within "#content-wrapper" do
        meetings.each do |meeting|
          expect(page).to have_no_role(:rowheader, text: meeting.title)
        end
      end
    end

    def expect_link_to_meeting_location(meeting)
      within "#content-wrapper" do
        within row_for(meeting) do
          expect(page).to have_link meeting.location
        end
      end
    end

    def expect_plaintext_meeting_location(meeting)
      within "#content-wrapper" do
        within row_for(meeting) do
          expect(page).to have_css("div.location", text: meeting.location)
          expect(page).to have_no_link meeting.location
        end
      end
    end

    def expect_no_meeting_location(meeting)
      within "#content-wrapper" do
        within row_for(meeting) do
          expect(page).to have_css("div.location", text: "")
        end
      end
    end

    def navigate_by_project_menu
      visit project_path(project)
      within "#main-menu" do
        click_on "Meetings", match: :first
      end
    end

    def navigate_by_global_menu
      visit root_path
      within "#main-menu" do
        click_on "Meetings", match: :first
      end
    end

    def navigate_by_modules_menu
      navigate_to_modules_menu_item("Meetings")
    end

    def path
      polymorphic_path([project, :meetings])
    end

    private

    def row_for(meeting)
      find(:role, :rowheader, text: meeting.title).ancestor(:row)
    end

    def more_menu(meeting)
      within "#content-wrapper" do
        within row_for(meeting) do
          click_on("more-button")

          find("li", text: "Download iCalendar event").ancestor("ul")
        end
      end
    end

    def submenu
      Components::Submenu.new
    end
  end
end
