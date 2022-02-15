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

describe 'Team planner project include', type: :feature, js: true do
  before do
    with_enterprise_token(:team_planner_view)
  end

  include_context 'with team planner full access'

  let(:dropdown) do
    ::Components::ProjectIncludeComponent.new 
  end

  let!(:role) { create(:role) }

  let!(:other_project) do
    create(:project, enabled_module_names: %w[work_package_tracking])
  end
  let!(:other_membership) { create :member, principal: user, project: other_project, roles: [role] }

  let!(:sub_project) do
    create(:project, parent: project, enabled_module_names: %w[work_package_tracking])
  end
  let!(:sub_membership) { create :member, principal: user, project: sub_project, roles: [role] }

  let!(:sub_sub_project) do
    create(:project, parent: sub_project, enabled_module_names: %w[work_package_tracking])
  end
  let!(:sub_sub_membership) { create :member, principal: user, project: sub_sub_project, roles: [role] }

  let!(:other_user) do
    create :user,
           firstname: 'Other',
           lastname: 'User',
           member_in_projects: [project, other_project, sub_project, sub_sub_project],
           member_with_permissions: %w[
             view_work_packages edit_work_packages view_team_planner manage_team_planner
           ]
  end

  let!(:user_outside_project) { create :user, firstname: 'Not', lastname: 'In Project' }

  context 'with an assigned work package' do
    let(:type_task) { create :type_task }
    let(:type_bug) { create :type_bug }
    let(:closed_status) { create :status, is_closed: true }

    let!(:task) do
      create :work_package,
             project: project,
             type: type_task,
             assigned_to: user,
             start_date: Time.zone.today - 2.day,
             due_date: Time.zone.today + 1.day,
             subject: 'A task for ' + user.name
    end
    let!(:sub_bug) do
      create :work_package,
             project: sub_project,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today - 10.days,
             due_date: Time.zone.today + 20.days,
             subject: 'A bug in sub-project for ' + user.name
    end
    let!(:sub_sub_bug) do
      create :work_package,
             project: sub_sub_project,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today - 1.day,
             due_date: Time.zone.today + 2.day,
             subject: 'A bug in sub-sub-project for ' + user.name
    end
    let!(:other_task) do
      create :work_package,
             project: project,
             type: type_task,
             assigned_to: other_user,
             start_date: Time.zone.today,
             due_date: Time.zone.today + 2.day,
             subject: 'A task for the other user'
    end
    let!(:other_other_task) do
      create :work_package,
             project: other_project,
             type: type_task,
             assigned_to: other_user,
             start_date: Time.zone.today - 2.day,
             due_date: Time.zone.today + 4.day,
             subject: 'A task for the other user in other-project'
    end

    before do
      project.types << type_bug
      project.types << type_task
      other_project.types << type_bug
      other_project.types << type_task
    end

    it 'can add and remove projects' do
      team_planner.visit!

      dropdown.expect_count 1
      dropdown.toggle!
      dropdown.expect_open

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id)

      dropdown.toggle_checkbox(project.id)
      dropdown.toggle_checkbox(other_project.id)
      dropdown.toggle_checkbox(sub_sub_project.id)

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.toggle_checkbox(sub_sub_project.id)

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id)

      dropdown.click_button 'Apply'
      dropdown.expect_closed
      dropdown.expect_count 2

      dropdown.toggle!

      dropdown.toggle_checkbox(sub_sub_project.id)
      dropdown.click_button 'Apply'
      dropdown.expect_closed
      dropdown.expect_count 3

      page.refresh

      dropdown.expect_count 3

      dropdown.toggle!

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.toggle_checkbox(sub_sub_project.id)
      dropdown.click_button 'Apply'
      dropdown.expect_closed
      dropdown.expect_count 2
    end

    it 'can clear the selection' do
      team_planner.visit!

      dropdown.expect_count 1
      dropdown.toggle!
      dropdown.expect_open

      dropdown.toggle_checkbox(project.id)
      dropdown.toggle_checkbox(other_project.id)
      dropdown.toggle_checkbox(sub_sub_project.id)

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.click_button 'Apply'
      dropdown.expect_closed
      dropdown.expect_count 3

      dropdown.toggle!

      dropdown.click_button 'Clear selection'

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id)

      dropdown.click_button 'Apply'
      dropdown.expect_closed
      dropdown.expect_count 1
    end

    it 'filter projects in the list' do
      team_planner.visit!

      dropdown.expect_count 1
      dropdown.toggle!
      dropdown.expect_open

      dropdown.toggle_checkbox(other_project.id)
      dropdown.toggle_checkbox(sub_sub_project.id)

      dropdown.search sub_sub_project.id

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_no_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.search other_project.id

      dropdown.expect_no_checkbox(project.id)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_project.id)

      dropdown.search ''

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.set_filter_selected true

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id, true)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.set_filter_selected false
      dropdown.toggle_checkbox(other_project.id)
      dropdown.set_filter_selected true

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_no_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.search other_project.id

      dropdown.expect_no_checkbox(project.id)
      dropdown.expect_no_checkbox(other_project.id)
      dropdown.expect_no_checkbox(sub_project.id)
      dropdown.expect_no_checkbox(sub_sub_project.id)

      dropdown.search ''

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_no_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)

      dropdown.set_filter_selected false

      dropdown.expect_checkbox(project.id, true)
      dropdown.expect_checkbox(other_project.id)
      dropdown.expect_checkbox(sub_project.id)
      dropdown.expect_checkbox(sub_sub_project.id, true)
    end

    it 'correctly filters work packages by project' do
      team_planner.visit!

      dropdown.expect_count 1

      team_planner.expect_empty_state
      team_planner.expect_assignee(user, present: false)
      team_planner.expect_assignee(other_user, present: false)

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add other_user.name
      end

      team_planner.expect_assignee user
      team_planner.expect_assignee other_user

      team_planner.within_lane(user) do
        team_planner.expect_event task
        team_planner.expect_event sub_bug, present: false
        team_planner.expect_event sub_sub_bug, present: false
      end

      team_planner.within_lane(other_user) do
        team_planner.expect_event other_task
        team_planner.expect_event other_other_task, present: false
      end

      dropdown.toggle!
      dropdown.toggle_checkbox(sub_sub_project.id)
      dropdown.click_button 'Apply'
      dropdown.expect_count 2

      team_planner.within_lane(user) do
        team_planner.expect_event task
        team_planner.expect_event sub_bug, present: false
        team_planner.expect_event sub_sub_bug
      end

      dropdown.toggle!
      dropdown.toggle_checkbox(other_project.id)
      dropdown.click_button 'Apply'
      dropdown.expect_count 3

      team_planner.within_lane(other_user) do
        team_planner.expect_event other_task
        team_planner.expect_event other_other_task
      end

      page.refresh

      team_planner.within_lane(other_user) do
        team_planner.expect_event other_task
        team_planner.expect_event other_other_task, present: false
      end

      team_planner.within_lane(user) do
        team_planner.expect_event task
        team_planner.expect_event sub_bug, present: false
        team_planner.expect_event sub_sub_bug
      end
    end
  end
end
