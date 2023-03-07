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
    create :user,
           firstname: 'Bernd',
           member_in_project: project,
           member_with_permissions: %w[
             view_work_packages view_calendar manage_calendar save_queries manage_public_queries share_calendars
           ]
  end

  let(:saved_query) do
    create(:query_with_view_work_packages_calendar,
           user: user_with_sharing_permission,
           project:,
           public: false)
  end

  context 'user with sufficient permissions' do

    # TODO: save_queries permission is mandatory to see settings button used for sharing option
    # does that make sense? the sharing feature therefore has an implicit dependency on this permission

    before do
      login_as user_with_sharing_permission
      calendar.visit!
    end

    context 'on not persisted calendar query' do

      # it 'shows disabled sharing menu item' do
      #   visit project_calendars_path(project)

      #   click_link "Create new calendar"

      #   # wait for settings button to become visible
      #   expect(page).to have_selector("#work-packages-settings-button")

      #   # click on settings button
      #   page.find("#work-packages-settings-button").click

      #   # expect disabled sharing menu item
      #   within "#settingsDropdown" do
      #     # expect(page).to have_button("Share calendar ...", disabled: true) # disabled selector not working
      #     expect(page).to have_selector(".menu-item.inactive", text: "Share calendar ...")
      #     page.click_button("Share calendar ...")

      #     # modal should not be shown
      #     expect(page).not_to have_selector('.spot-modal--header', text: "Share calendar")
      #   end

      # end
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
        page.find("#work-packages-settings-button").click

        # expect disabled sharing menu item
        within "#settingsDropdown" do
          # expect(page).to have_button("Share calendar ...", disabled: true) # disabled selector not working
          expect(page).to have_selector(".menu-item", text: "Share calendar ...")
          page.click_button("Share calendar ...")
          
        end

        expect(page).to have_selector('.spot-modal--header', text: "Share calendar")

      end
    end

  end

end
