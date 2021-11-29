#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'spec_helper'

describe 'Team planner', type: :feature, js: true do
  let(:project) do
    FactoryBot.create(:project, enabled_module_names: %w[work_package_tracking team_planner_view])
  end

  let(:user) do
    FactoryBot.create(:admin)
  end

  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    login_as(user)
  end

  it 'Filters the filters correctly' do
    visit project_path(project)

    within '#main-menu' do
      click_link 'Team planner'
    end

    expect(page)
      .to have_selector '.editable-toolbar-title--fixed', text: 'Team planner'

    filters.expect_filter_count("1")
    filters.open

    filters.expect_available_filter 'Author', present: true
    filters.expect_available_filter 'ID', present: true
    filters.expect_available_filter 'Finish date', present: false
    filters.expect_available_filter 'Start date', present: false
    filters.expect_available_filter 'Assignee', present: false
    filters.expect_available_filter 'Assignee or belonging group', present: false
    filters.expect_available_filter "Assignee's group", present: false
    filters.expect_available_filter "Assignee's role", present: false
  end
end
