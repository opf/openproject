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

describe 'Team planner index', js: true, with_ee: %i[team_planner_view] do
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking calendar_view])
  end

  shared_let(:user) do
    create :user,
           member_in_project: project,
           member_with_permissions: %w[
             view_work_packages
             edit_work_packages
             save_queries
             save_public_queries
             view_calendar
             manage_calendars
           ]
  end

  let(:query) do
    create(:query_with_view_work_packages_calendar,
           project:,
           user:,
           public: true)
  end

  let(:current_user) { user }

  before do
    login_as current_user
    query
    visit project_calendars_path(project)
  end

  context 'with no view' do
    let(:query) { nil }

    it 'shows an index action' do
      expect(page).to have_text 'There is currently nothing to display.'
      expect(page).to have_selector '.button', text: 'Calendar'
    end
  end

  context 'with an existing view' do
    it 'shows that view' do
      expect(page).to have_selector 'td', text: query.name
      expect(page).to have_selector "[data-qa-selector='calendar-remove-#{query.id}']"
    end

    context 'with another user with limited access' do
      let(:current_user) do
        create :user,
               firstname: 'Bernd',
               member_in_project: project,
               member_with_permissions: %w[view_work_packages view_calendar]
      end

      it 'does not show the create button' do
        expect(page).to have_selector 'td', text: query.name

        # Does not show the delete
        expect(page).to have_no_selector "[data-qa-selector='calendar-remove-#{query.id}']"

        # Does not show the create button
        expect(page).to have_no_selector '.button', text: 'Calendar'
      end

      context 'when the view is non-public' do
        let(:query) { create :query, user:, project:, public: false }

        it 'does not show a non-public view' do
          expect(page).to have_text 'There is currently nothing to display.'
          expect(page).to have_no_selector 'td', text: query.name

          # Does not show the delete
          expect(page).to have_no_selector "[data-qa-selector='team-planner-remove-#{query.id}']"

          # Does not show the create button
          expect(page).to have_no_selector '.button', text: 'Calendar'
        end
      end
    end
  end
end
