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

describe 'Workflow buttons', type: :feature, js: true do
  let(:permissions) { %i(view_work_packages edit_work_packages) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions )}
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) do
    FactoryGirl.create(:user,
                       member_through_role: role,
                       member_in_project: project)
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) do
    FactoryGirl.create(:work_package,
                       project: project,
                       assigned_to: user,
                       priority: default_priority,
                       status: default_status)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:default_priority) do
    FactoryGirl.create(:default_priority)
  end
  let(:immediate_priority) do
    FactoryGirl.create(:issue_priority, name: 'At once', position: IssuePriority.maximum(:position) + 1)
  end
  let(:default_status) do
    FactoryGirl.create(:default_status)
  end
  let(:closed_status) do
    FactoryGirl.create(:closed_status)
  end
  let(:workflows) do
    FactoryGirl.create(:workflow,
                       old_status: work_package.status,
                       new_status: closed_status,
                       role: role,
                       type: work_package.type)

    FactoryGirl.create(:workflow,
                       new_status: work_package.status,
                       old_status: closed_status,
                       role: role,
                       type: work_package.type)
  end

  before do
    login_as(admin)

    work_package
    immediate_priority
    workflows
  end

  scenario 'viewing workflow buttons' do
    # create custom actions
    visit custom_actions_path

    within '.toolbar-items' do
      click_link 'Custom action'
    end

    fill_in 'Name', with: 'Unassign'

    click_button 'Create'

    expect(page)
      .to have_current_path(custom_actions_path)

    expect(page)
      .to have_content 'Unassign'

    # use custom actions
    login_as(user)

    wp_page.visit!

    expect(page)
      .to have_selector('.workflow-button', text: 'Unassign')
    expect(page)
      .to have_selector('.workflow-button', text: 'Close')
    expect(page)
      .to have_selector('.workflow-button', text: 'Escalate')
    expect(page)
      .to have_selector('.workflow-button', text: 'Reset')

    within('.workflow-buttons') do
      click_button('Unassign')
    end

    wp_page.expect_attributes assignee: '-'
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    # Bump the lockVersion and by that force a conflict.
    WorkPackage.where(id: work_package.id).update_all(lock_version: 10)

    within('.workflow-buttons') do
      click_button('Escalate')
    end

    wp_page.expect_notification type: :error, message: I18n.t('api_v3.errors.code_409')

    wp_page.visit!

    within('.workflow-buttons') do
      click_button('Escalate')
    end

    wp_page.expect_attributes priority: immediate_priority.name
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    within('.workflow-buttons') do
      click_button('Close')
    end

    wp_page.expect_attributes status: closed_status.name
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    within('.workflow-buttons') do
      click_button('Reset')
    end

    wp_page.expect_attributes priority: default_priority.name,
                              status: default_status.name,
                              assignee: user.name
    wp_page.expect_notification message: 'Successful update'
  end
end
