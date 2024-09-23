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
require_relative "../../../modules/my_page/spec/support/pages/my/page"

RSpec.describe "Favorite projects", :js do
  shared_let(:project) { create(:public_project, name: "My favorite!", enabled_module_names: []) }
  shared_let(:other_project) { create(:public_project, name: "Other project", enabled_module_names: []) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i(edit_project select_project_modules view_work_packages),
             other_project => %i(edit_project select_project_modules view_work_packages)
           })
  end
  let(:projects_page) { Pages::Projects::Index.new }
  let(:top_menu) { Components::Projects::TopMenu.new }
  let(:my_page) do
    Pages::My::Page.new
  end

  context "as a user" do
    before do
      login_as user
    end

    it "allows favoriting and unfavoriting projects" do
      visit project_path(project)
      expect(page).to have_css "a", accessible_name: "Add to favorites"

      click_link_or_button(accessible_name: "Add to favorites")

      expect(page).to have_css "a", accessible_name: "Remove from favorite"

      project.reload
      expect(project).to be_favored_by(user)

      projects_page.visit!
      projects_page.open_filters
      projects_page.filter_by_favored "yes"

      expect(page).to have_text "My favorite!"

      projects_page.visit!
      projects_page.open_filters
      projects_page.filter_by_favored "no"

      expect(page).to have_no_text "My favorite!"

      visit home_path

      expect(page).to have_text "Favorite projects"
      expect(page).to have_test_selector "favorite-project", text: "My favorite!"

      retry_block do
        top_menu.toggle unless top_menu.open?
        top_menu.expect_open

        # projects are displayed initially
        top_menu.expect_result project.name
        top_menu.expect_result other_project.name
      end

      top_menu.switch_mode "Favorites"

      top_menu.expect_result project.name
      top_menu.expect_no_result other_project.name
    end

    context "when project is favored" do
      before do
        project.add_favoring_user(user)
        other_project.add_favoring_user(user)
        other_project.update! active: false
      end

      it "does not show archived projects" do
        visit home_path

        expect(page).to have_text "Favorite projects"
        expect(page).to have_test_selector "favorite-project", text: "My favorite!"
        expect(page).to have_no_text "Other project"

        my_page.visit!
        my_page.add_widget(1, 1, :within, "Favorite projects")
        expect(page).to have_text "My favorite!"
      end
    end

    context "when favoriting only one subproject" do
      before do
        project.update! parent: other_project
        project.add_favoring_user(user)
      end

      it "still shows up in top menu (Regression #54729)" do
        visit home_path

        expect(page).to have_text "Favorite projects"
        expect(page).to have_test_selector "favorite-project", text: "My favorite!"

        retry_block do
          top_menu.toggle unless top_menu.open?
          top_menu.expect_open

          # projects are displayed initially
          top_menu.expect_result project.name
          top_menu.expect_result other_project.name
        end

        top_menu.switch_mode "Favorites"

        top_menu.expect_result project.name
        # Parent is also shown
        top_menu.expect_result other_project.name
      end
    end
  end

  context "as an Anonymous User with not login required", with_settings: { login_required: false } do
    it "does not shows favored projects" do
      visit project_path(project)

      retry_block do
        top_menu.toggle unless top_menu.open?
        top_menu.expect_open

        within(".op-project-list-modal--header") do
          expect(page).to have_no_css("[data-test-selector=\"spot-toggle--option\"]", text: "Favorites")
        end
      end
    end
  end
end
