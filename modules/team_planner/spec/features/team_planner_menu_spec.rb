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

describe 'Team planner sidemenu', js: true do
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking team_planner_view])
  end

  context 'with a user that does not have create rights' do
    shared_let(:user_without_rights) do
      create :user,
             member_in_project: project,
             member_with_permissions: %w[
               view_work_packages edit_work_packages add_work_packages
               view_team_planner
             ]
    end

    current_user { user_without_rights }

    it 'hides the create team planner option if you do not have rights' do
      visit project_path(project)

      within '#main-menu' do
        click_link 'Team planners'
      end

      expect(page).not_to have_selector('[data-qa-selector="team-planner--create-button"]')
    end
  end

  context 'with a user that has create rights' do
    shared_let(:user_with_rights) do
      create :user,
             member_in_project: project,
             member_with_permissions: %w[
               view_work_packages edit_work_packages add_work_packages
               view_team_planner manage_team_planner
             ]
    end

    current_user { user_with_rights }

    context 'when EE disabled' do
      it 'does not show the create team planner option' do
        visit project_path(project)

        within '#main-menu' do
          click_link 'Team planners'
        end

        expect(page).to have_no_selector('[data-qa-selector="team-planner--create-button"]')
      end
    end

    context 'when EE enabled', with_ee: %i[team_planner_view] do
      it 'shows the create team planner option' do
        visit project_path(project)

        within '#main-menu' do
          click_link 'Team planners'
        end

        expect(page).to have_selector('[data-qa-selector="team-planner--create-button"]')
      end
    end
  end
end
