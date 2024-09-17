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

require_relative "new"

module Pages::Meetings
  class Index < Pages::Page
    attr_accessor :project

    def initialize(project:)
      super()

      self.project = project
    end

    def click_create_new
      click_on("add-meeting-button")

      New.new(project)
    end

    def expect_no_main_menu
      expect(page).to have_no_css "#main-menu"
    end

    def expect_no_create_new_button
      expect(page).not_to have_test_selector("add-meeting-button")
    end

    def expect_no_create_new_buttons
      expect(page).not_to have_test_selector("add-meeting-button")

      within "#main-menu" do
        expect(page).not_to have_test_selector "meeting--create-button"
      end
    end

    def expect_create_new_button
      expect(page).to have_test_selector("add-meeting-button")
    end

    def expect_create_new_buttons
      expect(page).to have_test_selector("add-meeting-button")

      within "#main-menu" do
        expect(page).to have_test_selector "meeting--create-button"
      end
    end

    def set_sidebar_filter(filter_name)
      submenu.click_item(filter_name)
    end

    def expect_no_meetings_listed
      within "#content-wrapper" do
        expect(page)
          .to have_content I18n.t(:no_results_title_text)
      end
    end

    def expect_meetings_listed_in_order(*meetings)
      within ".generic-table tbody" do
        listed_meeting_titles = all("tr td.title").map(&:text)

        expect(listed_meeting_titles).to eq(meetings.map(&:title))
      end
    end

    def expect_meetings_listed(*meetings)
      within ".generic-table tbody" do
        meetings.each do |meeting|
          expect(page).to have_css("td.title",
                                   text: meeting.title)
        end
      end
    end

    def expect_meetings_not_listed(*meetings)
      within "#content-wrapper" do
        meetings.each do |meeting|
          expect(page).to have_no_css("td.title",
                                      text: meeting.title)
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
          expect(page).to have_css("td.location", text: meeting.location)
          expect(page).to have_no_link meeting.location
        end
      end
    end

    def expect_no_meeting_location(meeting)
      within "#content-wrapper" do
        within row_for(meeting) do
          expect(page).to have_css("td.location", text: "")
        end
      end
    end

    def expect_to_be_on_page(number)
      expect(page)
        .to have_css(".op-pagination--item_current",
                     text: number)
    end

    def to_page(number)
      within ".op-pagination--pages" do
        click_on number.to_s
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
      find("td.title", text: meeting.title).ancestor("tr")
    end

    def submenu
      Components::Submenu.new
    end
  end
end
