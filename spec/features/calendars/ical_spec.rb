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

RSpec.describe 'iCal functionality', js: true, selenium: true do
  # steps to do:
  # 1) With setting not enabled, go to calendar page and see that it cannot be shared
  # 2) Go to the settings page, enable the setting
  # 3) Go back to to the calendar page and see that it can be shared now

  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:admin,
           member_in_project: project,
           member_with_permissions: %i[view_work_packages view_calendar manage_calendars])
  end

  before do
    login_as(user)
  end

  it "doesn't let a user share calendars without the setting being enabled" do
    visit project_path(project)

    within '#main-menu' do
      click_link 'Calendars'
    end

    click_link "Create new calendar"

    expect(page).to have_selector("#work-packages-settings-button")

    page.find_by_id('work-packages-settings-button').click

    within "#settingsDropdown" do
      expect(page).to have_selector(".menu-item.inactive", text: "Subscribe to iCalendar")
      page.click_button("Subscribe to iCalendar")

      expect(page).not_to have_selector('.spot-modal--header', text: "Subscribe to iCalendar")
    end
  end

  it 'navigates to iCal settings and enables the setting' do
    click_link 'OpenProject'
    click_link 'Administration'
    click_link 'Calendars and dates'
    click_link 'iCalendar'

    binding.pry
  end

end
