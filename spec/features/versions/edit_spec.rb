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

RSpec.describe "version edit" do
  let(:user) do
    create(:user,
           member_with_permissions: { version.project => %i[manage_versions view_work_packages] })
  end
  let(:version) { create(:version) }
  let(:new_version_name) { "A new version name" }

  before do
    login_as(user)
  end

  it "edit a version" do
    # from the version show page
    visit version_path(version)

    within ".toolbar" do
      click_link "Edit"
    end

    fill_in "Name", with: new_version_name

    click_button "Save"

    expect(page)
      .to have_current_path(version_path(version))
    expect(page)
      .to have_content new_version_name
  end
end
