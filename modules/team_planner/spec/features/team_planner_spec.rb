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

describe 'Team planner', type: :feature, js: true do
  before do
    with_enterprise_token(:team_planner_view)
  end

  include_context 'with team planner full access'

  it 'hides the internally used filters' do
    visit project_path(project)

    within '#main-menu' do
      click_link 'Team planner'
    end

    team_planner.expect_title

    filters.expect_filter_count("1")
    filters.open

    filters.open_available_filter_list
    filters.expect_available_filter 'Author', present: true
    filters.expect_available_filter 'Subject', present: true
    filters.expect_available_filter 'Finish date', present: false
    filters.expect_available_filter 'Start date', present: false
    filters.expect_available_filter 'Assignee', present: false
    filters.expect_available_filter 'Assignee or belonging group', present: false
    filters.expect_available_filter "Assignee's group", present: false
    filters.expect_available_filter "Assignee's role", present: false
  end

  context 'with an assigned work package' do
    let!(:other_user) do
      create :user,
                        firstname: 'Other',
                        lastname: 'User',
                        member_in_project: project,
                        member_with_permissions: %w[
                          view_work_packages edit_work_packages view_team_planner manage_team_planner
                        ]
    end
    let!(:user_outside_project) { create :user, firstname: 'Not', lastname: 'In Project' }
    let(:type_task) { create :type_task }
    let(:type_bug) { create :type_bug }
    let(:closed_status) { create :status, is_closed: true }

    let!(:other_task) do
      create :work_package,
                        project: project,
                        type: type_task,
                        assigned_to: other_user,
                        start_date: Time.zone.today - 1.day,
                        due_date: Time.zone.today + 1.day,
                        subject: 'A task for the other user'
    end
    let!(:other_bug) do
      create :work_package,
                        project: project,
                        type: type_bug,
                        assigned_to: other_user,
                        status: closed_status,
                        start_date: Time.zone.today - 1.day,
                        due_date: Time.zone.today + 1.day,
                        subject: 'Another task for the other user'
    end
    let!(:user_bug) do
      create :work_package,
                        project: project,
                        type: type_bug,
                        assigned_to: user,
                        start_date: Time.zone.today - 10.days,
                        due_date: Time.zone.today + 20.days,
                        subject: 'A task for the logged in user'
    end

    before do
      project.types << type_bug
      project.types << type_task
    end

    it 'renders a basic board' do
      team_planner.visit!

      team_planner.title

      team_planner.expect_empty_state
      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user, present: false)

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      team_planner.expect_empty_state(present: false)

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add other_user.name
      end

      team_planner.expect_assignee user
      team_planner.expect_assignee other_user

      team_planner.within_lane(user) do
        team_planner.expect_event user_bug
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event other_task
        team_planner.expect_event other_bug
      end

      # Add filter for type task
      filters.expect_filter_count("1")
      filters.open

      filters.add_filter_by('Type', 'is', [type_task.name])
      filters.expect_filter_by('Type', 'is', [type_task.name])
      filters.expect_filter_count("2")

      team_planner.expect_assignee(user, present: true)
      team_planner.expect_assignee(other_user, present: true)

      team_planner.within_lane(other_user) do
        team_planner.expect_event other_task
        team_planner.expect_event other_bug, present: false
      end

      # Open the split view for that task and change to bug
      split_view = team_planner.open_split_view(other_task)
      split_view.edit_field(:type).update(type_bug)
      split_view.expect_and_dismiss_toaster(message: "Successful update.")

      team_planner.expect_assignee(user, present: true)
      team_planner.expect_assignee(other_user, present: true)

      team_planner.expect_empty_state(present: false)
    end

    it 'can add and remove assignees' do
      team_planner.visit!

      team_planner.expect_empty_state
      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user, present: false)
      
      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      team_planner.expect_empty_state(present: false)
      team_planner.expect_assignee(user)
      team_planner.expect_assignee(other_user, present: false)
      
      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add other_user.name
      end

      team_planner.expect_assignee(user)
      team_planner.expect_assignee(other_user)

      team_planner.remove_assignee(user)

      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user)

      team_planner.remove_assignee(other_user)

      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user, present: false)
      team_planner.expect_empty_state

      # Try one more time to make sure deleting the full filter didn't kill the functionality
      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      team_planner.expect_assignee(user)
      team_planner.expect_assignee(other_user, present: false)
    end

    it 'filters possible assignees correctly' do
      team_planner.visit!

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.search_user_to_add user_outside_project.name
      end

      expect(page).to have_selector('.ng-option-disabled', text: "No items found")
      
      retry_block do
        team_planner.select_user_to_add user.name
      end
      
      team_planner.expect_assignee(user)

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.search_user_to_add user.name
      end

      expect(page).to have_selector('.ng-option-disabled', text: "No items found")
    end
  end
end
