#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Projects autocomplete page', type: :feature, js: true do
  let!(:user) { FactoryBot.create :user }

  let!(:project) do
    FactoryBot.create(:project,
                      name: 'Plain project',
                      identifier: 'plain-project')
  end

  let!(:project2) do
    FactoryBot.create(:project,
                      name: '<strong>foobar</strong>',
                      identifier: 'foobar')
  end

  let!(:project3) do
    FactoryBot.create(:project,
                      name: 'Plain other project',
                      parent: project2,
                      identifier: 'plain-project-2')
  end

  let!(:other_projects) do
    names = [
      "Very long project name with term at the END",
      "INK14 - Foo",
      "INK15 - Bar",
      "INK16 - Baz"
    ]

    names.map do |name|
      identifier = name.gsub(/[ \-]+/, "-").downcase

      FactoryBot.create :project, name: name, identifier: identifier
    end
  end
  let!(:non_member_project) do
    FactoryBot.create :project
  end
  let!(:public_project) do
    FactoryBot.create :public_project
  end
  # necessary to be able to see public projects
  let!(:non_member_role) { FactoryBot.create :non_member }
  # we only need the public permissions: view_project, :view_news
  let(:role) { FactoryBot.create(:role, permissions: []) }

  include BecomeMember

  let(:top_menu) { ::Components::Projects::TopMenu.new }

  before do
    ([project, project2, project3] + other_projects).each do |p|
      add_user_to_project! user: user, project: p, role: role
    end
    login_as user
    visit root_path
  end

  it 'allows to filter and select projects' do
    top_menu.toggle
    top_menu.expect_open

    # projects are displayed initially
    within(top_menu.search_results) do
      expect(page).to have_selector('.ui-menu-item-wrapper', text: project.name)
      # public project is displayed as it is public
      expect(page).to have_selector('.ui-menu-item-wrapper', text: public_project.name)
      # only projects the user is member in are displayed
      expect(page).to have_no_selector('.ui-menu-item-wrapper', text: non_member_project.name)
    end

    # Filter for projects
    top_menu.search '<strong'

    # Expect highlights
    within(top_menu.search_results) do
      expect(page).to have_selector('mark', text: '<strong')
      expect(page).to have_no_selector('strong')
    end

    # Expect fuzzy matches for plain
    top_menu.search 'Plain pr'
    within(top_menu.search_results) do
      expect(page).to have_selector('.ui-menu-item-wrapper', text: 'Plain project')
      expect(page).to have_no_selector('.ui-menu-item-wrapper', text: 'Plain other project')
    end

    # Expect hierarchy
    top_menu.clear_search

    within(top_menu.search_results) do
      expect(page).to have_selector('.ui-menu-item-wrapper', text: 'Plain project')
      expect(page).to have_selector('.ui-menu-item-wrapper', text: '<strong>foobar</strong>')
      expect(page).to have_selector('.ui-menu-item-wrapper', text: '» Plain other project')
    end

    # Show hierarchy of project
    top_menu.search 'Plain other project'

    within(top_menu.search_results) do
      expect(page).to have_selector('.ui-state-disabled .ui-menu-item-wrapper', text: '<strong>foobar</strong>')
      expect(page).to have_selector('.ui-menu-item-wrapper.ui-state-active', text: '» Plain other project')
    end

    # find terms at the end of project names
    top_menu.search 'END'
    within(top_menu.search_results) do
      expect(page).to have_selector(
        '.ui-menu-item-wrapper',
        text: 'Very long project name with term at the END'
      )
    end

    # Find literal matches exclusively if present
    top_menu.search 'INK15'
    within(top_menu.search_results) do
      expect(page).to have_selector('.ui-menu-item-wrapper', text: 'INK15 - Bar')
      expect(page).to have_no_selector('.ui-menu-item-wrapper', text: 'INK14 - Foo')
      expect(page).to have_no_selector('.ui-menu-item-wrapper', text: 'INK16 - Baz')
    end

    # Visit a project
    top_menu.search_and_select '<strong'
    top_menu.expect_current_project project2.name

    # Keeps the current module
    visit project_news_index_path(project2)
    expect(page).to have_selector('.news-menu-item.selected')

    top_menu.toggle
    top_menu.expect_open
    top_menu.search_and_select 'Plain project'

    expect(current_path).to eq(project_news_index_path(project))
    expect(page).to have_selector('.news-menu-item.selected')
  end
end
