# frozen_string_literal: true

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
require "support/components/projects/top_menu"

RSpec.describe "Projects navigation", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages]
           })
  end
  shared_let(:admin) { create(:admin) }

  let(:top_menu) { Components::Projects::TopMenu.new }

  context "as a user with all permissions" do
    before do
      login_as admin
    end

    it "can deselect the current project and keep the module" do
      visit project_work_packages_path(project)
      top_menu.toggle

      # The currently active project is highlighted and removable
      within top_menu.search_results do
        expect(page).to have_css(top_menu.remove_item_selector, count: 1)
        expect(page).to have_css(top_menu.active_item_selector, count: 1)
        page.find(top_menu.remove_item_selector).click
      end

      # Once removed, the user is redirected to the global WorkPackages page
      expect(page).to have_current_path(work_packages_path)

      # Navigate to another module in a project
      visit project_roadmap_path(project)

      # Remove the project again
      top_menu.toggle
      within top_menu.search_results do
        page.find(top_menu.remove_item_selector).click
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

  context "with workspace type badges in project dropdown" do
    shared_let(:portfolio_project) { create(:portfolio, name: "Test Portfolio") }
    shared_let(:program_project) { create(:program, name: "Test Program") }
    shared_let(:regular_project) { project }

    before do
      login_as admin
      visit home_path
      top_menu.toggle!
    end

    it "displays badges for portfolio and program workspaces but not for regular projects" do
      top_menu.expect_result(portfolio_project.name, workspace_badge: "Portfolio")
      top_menu.expect_result(program_project.name, workspace_badge: "Program")
      top_menu.expect_result(regular_project.name, workspace_badge: false)
    end
  end
end
