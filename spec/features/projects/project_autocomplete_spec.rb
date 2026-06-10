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

RSpec.describe "Projects autocomplete page", :js do
  shared_let(:user) { create(:user) }
  # we only need the public permissions: view_project, :view_news
  shared_let(:role) { create(:project_role, permissions: []) }

  shared_let(:portfolio) do
    create(:portfolio, name: "Test Portfolio", members: { user => role })
  end
  shared_let(:program) do
    create(:program, name: "Test Program", members: { user => role })
  end
  shared_let(:project) do
    create(:project, name: "Plain project", identifier: "plain-project", members: { user => role })
  end
  shared_let(:project2) do
    create(:project,
           name: "<strong>foobar</strong>",
           identifier: "foobar",
           members: { user => role })
  end
  shared_let(:project3) do
    create(:project,
           name: "Plain other project",
           parent: project2,
           identifier: "plain-project-2",
           members: { user => role })
  end
  shared_let(:project4) do
    create(:project,
           name: "Project with different name and identifier",
           parent: project2,
           identifier: "plain-project-4",
           members: { user => role })
  end
  shared_let(:other_projects) do
    names = [
      "Very long project name with term at the END",
      "INK14 - Foo",
      "INK15 - Bar",
      "INK16 - Baz"
    ]

    names.map do |name|
      identifier = name.gsub(/[ -]+/, "-").downcase

      create(:project, name:, identifier:, members: { user => role })
    end
  end
  shared_let(:non_member_project) { create(:project) }
  shared_let(:public_project) { create(:public_project) }

  let(:top_menu) { Components::Projects::TopMenu.new }

  before do
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

    # Expect result is shown and HTML in the project name is escaped, not rendered
    within(top_menu.search_results) do
      expect(page).to have_no_css("strong")
    end

    # Expect fuzzy matches for multiple substrings
    top_menu.search "Plain pr"
    top_menu.expect_result "Plain project"
    top_menu.expect_result "Plain other project"
    top_menu.expect_no_result "Project with different name and identifier"

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
    top_menu.expect_item_with_hierarchy_level hierarchy_level: 2,
                                              item_name: "Plain other project"

    # Show hierarchy of project
    top_menu.search "Plain other project"

    top_menu.expect_result "<strong>foobar</strong>", disabled: true
    top_menu.expect_item_with_hierarchy_level hierarchy_level: 2,
                                              item_name: "Plain other project"

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

    expect(page).to have_current_path(project_news_index_path(project),
                                      ignore_query: true)
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
    top_menu.search_and_select "<strong"

    top_menu.expect_current_project project2.name
  end

  it "displays workspace type badges for portfolios and programs" do
    retry_block do
      top_menu.toggle unless top_menu.open?
      top_menu.expect_open

      top_menu.expect_result portfolio.name, workspace_badge: "Portfolio"
      top_menu.expect_result program.name, workspace_badge: "Program"
      top_menu.expect_result project.name, workspace_badge: false
    end
  end
end
