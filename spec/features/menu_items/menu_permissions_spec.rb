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

RSpec.describe "menu permissions", :js, :with_cuprite do
  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[manage_versions view_work_packages] })
  end
  let(:admin) { create(:admin) }

  let(:project) { create(:project) }

  context "as an admin" do
    before do
      login_as admin

      # Allowed to see the settings version page
      visit project_settings_versions_path(project)
    end

    it "I can see all menu entries" do
      expect(page).to have_css("#menu-sidebar .op-menu--item-title", text: "Versions")
      expect(page).to have_css("#menu-sidebar .op-menu--item-title", text: "Information")
      expect(page).to have_css("#menu-sidebar .op-menu--item-title", text: "Modules")
    end

    specify "the parent node directs to the general settings page" do
      # The settings menu item exists
      expect(page).to have_css("#menu-sidebar .main-item-wrapper", text: "Project settings", visible: false)

      # Clicking the menu parent item leads to the version page
      find(".main-menu--parent-node", text: "Project settings").click
      expect(page).to have_current_path "/projects/#{project.identifier}/settings/general"
    end
  end

  context "as a user who can only manage_versions" do
    before do
      login_as user

      # Allowed to see the settings version page
      visit project_settings_versions_path(project)
    end

    it "I can only see the version settings page" do
      expect(page).to have_css("#menu-sidebar .op-menu--item-title", text: "Versions")
      expect(page).to have_no_css("#menu-sidebar .op-menu--item-title", text: "Information")
      expect(page).to have_no_css("#menu-sidebar .op-menu--item-title", text: "Modules")
    end

    specify "the parent node directs to the only visible children page" do
      # The settings menu item exists
      expect(page).to have_css("#menu-sidebar .main-item-wrapper", text: "Project settings", visible: false)

      # Clicking the menu parent item leads to the version page
      find(".main-menu--parent-node", text: "Project settings").click
      expect(page).to have_current_path(project_settings_versions_path(project))
    end
  end
end
