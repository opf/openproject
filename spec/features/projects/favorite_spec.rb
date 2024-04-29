#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Favorite projects",
               :js,
               with_flag: :favorite_projects do
  shared_let(:project) { create(:project, name: "My favorite!", enabled_module_names: []) }
  shared_let(:other_project) { create(:project, name: "Other project", enabled_module_names: []) }
  let(:permissions) { %i(edit_project select_project_modules view_work_packages) }
  let(:projects_page) { Pages::Projects::Index.new }
  let(:top_menu) { Components::Projects::TopMenu.new }

  current_user do
    create(:user, member_with_permissions: { project => permissions, other_project => permissions })
  end

  it "allows favoriting and unfavoriting projects" do
    visit project_path(project)
    expect(page).to have_selector 'a', accessible_name: "Mark as favorite"

    click_link_or_button(accessible_name: "Mark as favorite")

    expect(page).to have_selector 'a', accessible_name: "Remove from favorite"

    project.reload
    expect(project).to be_favored_by(current_user)

    projects_page.visit!
    projects_page.open_filters
    projects_page.filter_by_favored "yes"

    expect(page).to have_text 'My favorite!'

    projects_page.visit!
    projects_page.open_filters
    projects_page.filter_by_favored "no"

    expect(page).to have_no_text 'My favorite!'

    visit home_path

    expect(page).to have_text 'Favored projects'
    expect(page).to have_test_selector 'favorite-project', text: 'My favorite!'

    retry_block do
      top_menu.toggle unless top_menu.open?
      top_menu.expect_open

      # projects are displayed initially
      top_menu.expect_result project.name
      top_menu.expect_result other_project.name
    end

    top_menu.switch_mode "Favored"

    top_menu.expect_result project.name
    top_menu.expect_no_result other_project.name
  end
end
