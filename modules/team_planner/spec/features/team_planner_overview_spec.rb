# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++
#

require 'spec_helper'
require_relative 'shared_context'

RSpec.describe 'Team planner overview',
               :js,
               :with_cuprite,
               with_ee: %i[team_planner_view],
               with_flag: { more_global_index_pages_active: true } do
  include_context 'with team planner full access'

  let(:current_user) { user }
  let(:query) { create(:query, user:, project:, public: true) }
  let(:team_plan) { create(:view_team_planner, query:) }

  before do
    login_as current_user
    team_plan
    visit team_planners_path
  end

  it 'renders a global menu with its item selected' do
    within '#main-menu' do
      expect(page).to have_selector '.selected', text: 'Team planners'
    end
  end

  it 'shows no create button' do
    expect(page).not_to have_selector '.button', text: 'Team planner'
  end

  context 'with no view' do
    let(:team_plan) { nil }

    it 'shows an overview action' do
      expect(page).to have_text 'There is currently nothing to display.'
    end
  end

  context 'with an existing view' do
    it 'shows that view' do
      expect(page).to have_selector 'td', text: query.name
    end

    context 'with another user with limited access' do
      let(:current_user) do
        create(:user,
               firstname: 'Bernd',
               member_in_project: project,
               member_with_permissions: %w[view_work_packages view_team_planner])
      end

      it 'does not show the management buttons' do
        expect(page).to have_selector 'td', text: query.name

        # Does not show the delete
        expect(page).not_to have_selector "[data-qa-selector='team-planner-remove-#{query.id}']"

        # Does not show the create button
        expect(page).not_to have_selector '.button', text: 'Team planner'
      end

      context 'when the view is non-public' do
        let(:query) { create(:query, user:, project:, public: false) }

        it 'does not show a non-public view' do
          expect(page).to have_text 'There is currently nothing to display.'
          expect(page).not_to have_selector 'td', text: query.name

          # Does not show the delete
          expect(page).not_to have_selector "[data-qa-selector='team-planner-remove-#{query.id}']"

          # Does not show the create button
          expect(page).not_to have_selector '.button', text: 'Team planner'
        end
      end
    end
  end
end
