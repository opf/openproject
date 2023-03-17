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

require 'spec_helper'
require_relative './shared_context'

describe 'Calendar sharing via ical', js: true do
  include_context 'with calendar full access'

  let!(:user_with_sharing_permission) do
    create(:user,
           firstname: 'Bernd',
           member_in_project: project,
           member_with_permissions: %w[
             view_work_packages
             edit_work_packages
             save_queries
             save_public_queries
             view_calendar
             manage_calendars
             share_calendars
           ])
  end

  let!(:user_without_sharing_permission) do
    create(:user,
           firstname: 'Bernd',
           member_in_project: project,
           member_with_permissions: %w[
             view_work_packages
             edit_work_packages
             save_queries
             save_public_queries
             view_calendar
             manage_calendars
           ])
  end

  let(:saved_query) do
    create(:query_with_view_work_packages_calendar,
           user: user_with_sharing_permission,
           project:,
           public: false)
  end

  context 'with sufficient permissions' do
    # TODO: save_queries permission is mandatory to see settings button used for sharing option
    # does that make sense? the sharing feature therefore has an implicit dependency on this permission

    before do
      login_as user_with_sharing_permission
      calendar.visit!
    end

    context 'on not persisted calendar query' do
      it 'shows disabled sharing menu item' do
        visit project_calendars_path(project)

        click_link "Create new calendar"

        # wait for settings button to become visible
        expect(page).to have_selector("#work-packages-settings-button")

        # click on settings button
        page.find_by_id('work-packages-settings-button').click

        # expect disabled sharing menu item
        within "#settingsDropdown" do
          # expect(page).to have_button("Share iCalendar", disabled: true) # disabled selector not working
          expect(page).to have_selector(".menu-item.inactive", text: "Share iCalendar")
          page.click_button("Share iCalendar")

          # modal should not be shown
          expect(page).not_to have_selector('.spot-modal--header', text: "Share iCalendar")
        end
      end
    end

    context 'on persisted calendar query' do
      it 'shows sharing menu item and sharing modal if clicked' do
        saved_query

        visit project_calendars_path(project)

        within '#content' do
          click_link saved_query.name
        end

        loading_indicator_saveguard

        # wait for settings button to become visible
        expect(page).to have_selector("#work-packages-settings-button")

        # click on settings button
        page.find_by_id('work-packages-settings-button').click

        # expect disabled sharing menu item
        within "#settingsDropdown" do
          # expect(page).to have_button("Share iCalendar", disabled: true) # disabled selector not working
          expect(page).to have_selector(".menu-item", text: "Share iCalendar")
          page.click_button("Share iCalendar")
        end

        expect(page).to have_selector('.spot-modal--header', text: "Share iCalendar")
        expect(page).to have_xpath('//a[contains(@href, "/ical?ical_token=")]')

        click_button "Copy URL"

        # Not working in test env, probably due to missing clipboard permissions of the headless browser
        # expect(page).to have_content("URL copied to clipboard")

        # TODO: Not able to test if the URL was actuall copied to the clipboard
        # Tried following without success
        # https://copyprogramming.com/howto/emulating-a-clipboard-copy-paste-with-selinum-capybara
      end
    end
  end

  context 'without sufficient permissions' do
    before do
      login_as user_without_sharing_permission
      calendar.visit!
    end

    context 'on persisted calendar query' do
      it 'shows disabled sharing menu item' do
        visit project_calendars_path(project)

        click_link "Create new calendar"

        # wait for settings button to become visible
        expect(page).to have_selector("#work-packages-settings-button")

        # click on settings button
        page.find_by_id('work-packages-settings-button').click

        # expect disabled sharing menu item
        within "#settingsDropdown" do
          # expect(page).to have_button("Share iCalendar", disabled: true) # disabled selector not working
          expect(page).to have_selector(".menu-item.inactive", text: "Share iCalendar")
          page.click_button("Share iCalendar")

          # modal should not be shown
          expect(page).not_to have_selector('.spot-modal--header', text: "Share iCalendar")
        end
      end
    end
  end
end
