#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/projects/projects_page'

describe 'Projects autocomplete page', type: :feature, js: true do
  let!(:admin) { FactoryGirl.create :admin }

  let!(:project) do
    FactoryGirl.create(:project,
                       name: 'Plain project',
                       identifier: 'plain-project')
  end

  let!(:project2) do
    FactoryGirl.create(:project,
                       name: '<strong>foobar</strong>',
                       identifier: 'foobar')
  end

  let!(:project3) do
    FactoryGirl.create(:project,
                       name: 'Plain other project',
                       parent: project2,
                       identifier: 'plain-project-2')
  end

  let(:top_menu) { ::Components::Projects::TopMenu.new }

  before do
    login_as admin
    visit root_path
  end

  it 'allows to filter and select projects' do
    top_menu.toggle
    top_menu.expect_open

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
      expect(page).to have_selector('.ui-menu-item-wrapper', text: 'Plain project')
    end

    # Visit a project
    top_menu.search_and_select '<strong'
    top_menu.expect_current_project project2.name

    # Keeps the current module
    visit project_work_packages_path(project2)
    expect(page).to have_selector('.work-packages-menu-item.selected')

    top_menu.toggle
    top_menu.expect_open
    top_menu.search_and_select 'Plain project'

    expect(current_path).to eq(project_work_packages_path(project))
    expect(page).to have_selector('.work-packages-menu-item.selected')
  end
end
