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

RSpec.describe "Projects navigation", :js, :with_cuprite do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages]
           })
  end
  shared_let(:admin) { create(:admin) }

  context "as a user with all permissions" do
    before do
      login_as admin
    end

    it "can deselect the current project and keep the module" do
      visit project_work_packages_path(project)
      page.find_test_selector("op-projects-menu").click

      # The currently active project is highlighted and removable
      page.within_test_selector("op-header-project-select--list") do
        expect(page).to have_test_selector("op-header-project-select--item-remove-icon", count: 1)
        expect(page).to have_test_selector("op-header-project-select--active-item", count: 1)

        page.find_test_selector("op-header-project-select--item-remove-icon").click
      end

      # Once removed, the user is redirected to the global WorkPackages page
      expect(page).to have_current_path(work_packages_path)

      # Navigate to another module in a project
      visit project_roadmap_path(project)

      # Remove the project again
      page.find_test_selector("op-projects-menu").click
      page.within_test_selector("op-header-project-select--list") do
        page.find_test_selector("op-header-project-select--item-remove-icon").click
      end

      # Once removed, the user is redirected to the home page
      expect(page).to have_current_path(home_path(jump: "roadmap"))
    end
  end

  context "as a user with limited permissions" do
    before do
      login_as user
    end

    it "does not redirect to the global menu" do
      visit home_path(jump: "calendar_view")

      # The user is not redirected to the module but remains on the home page
      expect(page).to have_no_current_path(project_calendars_path(project))
      expect(page).to have_current_path(home_path(jump: "calendar_view"))
    end
  end
end
