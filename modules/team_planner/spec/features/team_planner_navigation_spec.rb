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
require_relative './shared_context'

describe 'Team planner', type: :feature, js: true, with_ee: %i[team_planner_view] do
  include_context 'with team planner full access'

  # We need a default status
  shared_let(:default_status) { create :default_status }

  it 'redirects to the first active plan' do
    visit project_path(project)

    within '#main-menu' do
      click_link 'Team planner'
    end

    team_planner.expect_title
    team_planner.save_as 'Foobar'

    visit project_path(project)

    within '#main-menu' do
      click_link 'Team planner'
    end

    query = View.where(type: 'team_planner').last.query
    expect(query.name).to eq 'Foobar'

    expect(page).to have_current_path /query_id=#{query.id}/
  end

  shared_examples 'loads a new team planner' do
    it do
      visit project_path(project)

      within '#main-menu' do
        click_link 'Team planner'
      end

      team_planner.expect_title
      expect(page).to have_no_current_path /query_id=#{query.id}/
    end
  end

  shared_examples 'loads the query view' do
    it do
      visit project_path(project)

      within '#main-menu' do
        click_link 'Team planner'
      end

      team_planner.expect_title query.name
      expect(page).to have_current_path /query_id=#{query.id}/
    end
  end

  context 'with an existing saved plan' do
    shared_let(:other_user) { create :user }
    let!(:view) { create :view_team_planner, query: query }

    context 'when the query is from another user and private' do
      let!(:query) { create :query, user: other_user, project: project, public: false }

      it_behaves_like 'loads a new team planner'
    end

    context 'when the query is from another user and public' do
      let!(:query) { create :query, user: other_user, project: project, public: true }

      it_behaves_like 'loads the query view'
    end

    context 'when the query is from the same user and private' do
      let!(:query) { create :query, user: user, project: project, public: false }

      it_behaves_like 'loads the query view'
    end
  end

  context 'with an existing plan and creating a new one' do
    let!(:view) { create :view_team_planner, query: query }
    let!(:query) { create :query, user: user, project: project, public: true }

    it 'allows to reload with query props active' do
      team_planner.visit!

      team_planner.expect_assignee(user, present: false)

      click_on 'Create new planner'
      team_planner.expect_assignee(user, present: false)

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      team_planner.expect_assignee(user)

      page.driver.refresh

      expect(page).to have_current_path /query_props=/
      expect(page).to have_current_path /cview=/

      team_planner.expect_assignee(user)
    end
  end
end
