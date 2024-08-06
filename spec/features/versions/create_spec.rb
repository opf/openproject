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

RSpec.describe "version create", js: false do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[manage_versions view_work_packages] })
  end
  let(:project) { create(:project) }
  let(:new_version_name) { "A new version name" }

  before do
    login_as(user)
  end

  context "create a version" do
    it "and redirect to default" do
      visit new_project_version_path(project)

      fill_in "Name", with: new_version_name
      click_on "Create"

      expect(page).to have_current_path(project_settings_versions_path(project))
      expect(page).to have_content new_version_name
    end

    it "and redirect back to where you started" do
      visit project_roadmap_path(project)
      click_on "New version"

      fill_in "Name", with: new_version_name
      click_on "Create"

      expect(page).to have_text("Successful creation")
      expect(page).to have_current_path(project_roadmap_path(project))
      expect(page).to have_content new_version_name
    end
  end
end
