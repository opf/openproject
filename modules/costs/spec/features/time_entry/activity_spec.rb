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

RSpec.describe "Time entry activity", :js do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  before do
    login_as(admin)
  end

  it "allows creating new activities and activating them on projects" do
    visit admin_settings_time_entry_activities_path

    page.find_test_selector("add-enumeration-button").click

    fill_in "Name", with: "A new activity"
    click_on("Save")

    # we are redirected back to the index page
    expect(page).to have_current_path(admin_settings_time_entry_activities_path)
    expect(page).to have_content("A new activity")

    # It allows editing (Regression #62459)
    click_link "A new activity"

    fill_in "Name", with: "Development"
    click_on("Save")

    expect(page).to have_current_path(admin_settings_time_entry_activities_path)
    expect(page).to have_content("Development")

    expect(TimeEntryActivity).to exist(name: "Development")
    expect(TimeEntryActivity).not_to exist(name: "A new activity")

    visit project_settings_general_path(project)

    click_on "Time and costs"

    expect(page).to have_field("Development", checked: true)

    uncheck "Development"

    click_on "Save"

    expect(page).to have_content "Successful update."

    expect(page).to have_field("Development", checked: false)
  end
end
