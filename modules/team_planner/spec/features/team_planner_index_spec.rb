#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

describe 'Team planner index', js: true, with_ee: %i[team_planner_view] do
  include_context 'with team planner full access'

  let(:current_user) { user }
  let(:query) { create :query, user:, project:, public: true }
  let(:team_plan) { create :view_team_planner, query: }

  before do
    login_as current_user
    team_plan
    visit project_team_planners_path(project)
  end

  context 'with no view' do
    let(:team_plan) { nil }

    it 'shows an index action' do
      expect(page).to have_text 'There is currently nothing to display.'
      expect(page).to have_selector '.button', text: 'Team planner'
    end

    it 'can create an action through the sidebar' do
      find('[data-qa-selector="team-planner--create-button"]').click

      team_planner.expect_title

      # Also works from the frontend
      find('[data-qa-selector="team-planner--create-button"]').click

      team_planner.expect_no_toaster
      team_planner.expect_title
    end
  end

  context 'with an existing view' do
    it 'shows that view' do
      expect(page).to have_selector 'td', text: query.name
      expect(page).to have_selector "[data-qa-selector='team-planner-remove-#{query.id}']"
    end

    context 'with another user with limited access' do
      let(:current_user) do
        create :user,
               firstname: 'Bernd',
               member_in_project: project,
               member_with_permissions: %w[view_work_packages view_team_planner]
      end

      it 'does not show the create button' do
        expect(page).to have_selector 'td', text: query.name

        # Does not show the delete
        expect(page).to have_no_selector "[data-qa-selector='team-planner-remove-#{query.id}']"

        # Does not show the create button
        expect(page).to have_no_selector '.button', text: 'Team planner'
      end

      context 'when the view is non-public' do
        let(:query) { create :query, user:, project:, public: false }

        it 'does not show a non-public view' do
          expect(page).to have_text 'There is currently nothing to display.'
          expect(page).to have_no_selector 'td', text: query.name

          # Does not show the delete
          expect(page).to have_no_selector "[data-qa-selector='team-planner-remove-#{query.id}']"

          # Does not show the create button
          expect(page).to have_no_selector '.button', text: 'Team planner'
        end
      end
    end
  end
end
