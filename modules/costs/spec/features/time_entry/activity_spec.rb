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

RSpec.describe "Time entry activity" do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  before do
    login_as(admin)
  end

  it "supports CRUD" do
    visit enumerations_path

    page.find_test_selector("create-enumeration-time-entry-activity").click

    fill_in "Name", with: "A new activity"
    click_on("Create")

    expect(page.current_path)
      .to eql enumerations_path

    expect(page)
      .to have_content("A new activity")

    visit project_settings_general_path(project)

    click_on "Time tracking activities"

    expect(page)
      .to have_field("A new activity", checked: true)

    uncheck "A new activity"

    click_on "Save"

    expect(page)
      .to have_content "Successful update."

    expect(page)
      .to have_field("A new activity", checked: false)
  end
end
