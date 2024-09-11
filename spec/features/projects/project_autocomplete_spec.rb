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

RSpec.describe "Projects autocomplete page", :js, :with_cuprite do
  let!(:user) { create(:user) }
  let(:top_menu) { Components::Projects::TopMenu.new }

  let!(:project) do
    create(:project,
           name: "Plain project",
           identifier: "plain-project")
  end

  let!(:project2) do
    create(:project,
           name: "<strong>foobar</strong>",
           identifier: "foobar")
  end

  let!(:project3) do
    create(:project,
           name: "Plain other project",
           parent: project2,
           identifier: "plain-project-2")
  end
  let!(:project4) do
    create(:project,
           name: "Project with different name and identifier",
           parent: project2,
           identifier: "plain-project-4")
  end

  let!(:other_projects) do
    names = [
      "Very long project name with term at the END",
      "INK14 - Foo",
      "INK15 - Bar",
      "INK16 - Baz"
    ]

    names.map do |name|
      identifier = name.gsub(/[ -]+/, "-").downcase

      create(:project, name:, identifier:)
    end
  end
  let!(:non_member_project) do
    create(:project)
  end
  let!(:public_project) do
    create(:public_project)
  end
  # necessary to be able to see public projects
  let!(:non_member_role) { create(:non_member) }
  # we only need the public permissions: view_project, :view_news
  let(:role) { create(:project_role, permissions: []) }

  include BecomeMember

  before do
    ([project, project2, project3] + other_projects).each do |p|
      add_user_to_project! user:, project: p, role:
    end
    login_as user
    visit root_path
  end

  it "allows to filter and select projects" do
    retry_block do
      top_menu.toggle unless top_menu.open?
      top_menu.expect_open

      # projects are displayed initially
      top_menu.expect_result project.name
      # public project is displayed as it is public
      top_menu.expect_result public_project.name
      # only projects the user is member in are displayed
      top_menu.expect_no_result non_member_project.name
    end

    # Filter for projects
    top_menu.search "<strong"

    # Expect highlights
    within(top_menu.search_results) do
      expect(page).to have_css(".op-search-highlight", text: "<strong")
      expect(page).to have_no_css("strong")
    end

    # Expect fuzzy matches for plain
    top_menu.search "Plain pr"
    top_menu.expect_result "Plain project"
    top_menu.expect_no_result "Plain other project"

    # Expect search to match names only and not the identifier
    top_menu.clear_search

    top_menu.search "plain"
    top_menu.expect_result "Plain project"
    top_menu.expect_result "Plain other project"
    top_menu.expect_no_result "Project with different name and identifier"

    # Expect hierarchy
    top_menu.clear_search

    top_menu.expect_result "Plain project"
    top_menu.expect_result "<strong>foobar</strong>", disabled: true
    top_menu.expect_item_with_hierarchy_level hierarchy_level: 2, item_name: "Plain other project"

    # Show hierarchy of project
    top_menu.search "Plain other project"

    top_menu.expect_result "<strong>foobar</strong>", disabled: true
    top_menu.expect_item_with_hierarchy_level hierarchy_level: 2, item_name: "Plain other project"

    # find terms at the end of project names
    top_menu.search "END"
    top_menu.expect_result "Very long project name with term at the END"

    # Find literal matches exclusively if present
    top_menu.search "INK15"
    top_menu.expect_result "INK15 - Bar"
    top_menu.expect_no_result "INK14 - Foo"
    top_menu.expect_no_result "INK16 - Baz"

    # Visit a project
    top_menu.search_and_select "<strong"
    top_menu.expect_current_project project2.name

    # Keeps the current module
    visit project_news_index_path(project2)
    expect(page).to have_css(".news-menu-item.selected")

    retry_block do
      top_menu.toggle
      top_menu.expect_open
      top_menu.search_and_select "Plain project"
    end

    expect(page).to have_current_path(project_news_index_path(project), ignore_query: true)
    expect(page).to have_css(".news-menu-item.selected")
  end

  it "navigates to the first project upon hitting enter in the search bar" do
    retry_block do
      top_menu.toggle unless top_menu.open?
      top_menu.expect_open

      # projects are displayed initially
      top_menu.expect_result project.name
    end

    # Filter for projects
    top_menu.search "<strong"

    # Visit a project
    top_menu.autocompleter.send_keys :enter

    top_menu.expect_current_project project2.name
  end
end
