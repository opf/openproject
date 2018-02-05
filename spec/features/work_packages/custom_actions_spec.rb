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

describe 'Custom actions', type: :feature, js: true do
  let(:permissions) { %i(view_work_packages edit_work_packages) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let!(:other_role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) do
    FactoryGirl.create(:user,
                       firstname: 'A',
                       lastname: 'User',
                       member_through_role: role,
                       member_in_project: project)
  end
  let(:project) { FactoryGirl.create(:project) }
  let!(:work_package) do
    FactoryGirl.create(:work_package,
                       project: project,
                       assigned_to: user,
                       priority: default_priority,
                       status: default_status)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:default_priority) do
    FactoryGirl.create(:default_priority, name: 'Normal')
  end
  let!(:immediate_priority) do
    FactoryGirl.create(:issue_priority,
                       name: 'At once',
                       position: IssuePriority.maximum(:position) + 1)
  end
  let(:default_status) do
    FactoryGirl.create(:default_status)
  end
  let(:closed_status) do
    FactoryGirl.create(:closed_status, name: 'Closed')
  end
  let(:rejected_status) do
    FactoryGirl.create(:closed_status, name: 'Rejected')
  end
  let!(:workflows) do
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
    FactoryGirl.create(:workflow,
                       old_status: work_package.status,
                       new_status: rejected_status,
                       role: role,
                       type: work_package.type)
  end
  let!(:list_custom_field) do
    cf = FactoryGirl.create(:list_wp_custom_field, multi_value: true)

    project.work_package_custom_fields = [cf]
    work_package.type.custom_fields = [cf]

    cf
  end
  let(:selected_list_custom_field_options) do
    [list_custom_field.custom_options.first, list_custom_field.custom_options.last]
  end
  let(:index_ca_page) { Pages::Admin::CustomActions::Index.new }

  before do
    login_as(admin)
  end

  scenario 'viewing workflow buttons' do
    # create custom action 'Unassign'
    index_ca_page.visit!

    new_ca_page = index_ca_page.new
    new_ca_page.set_name('Unassign')
    new_ca_page.add_action('Assignee', '-')
    new_ca_page.create

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign')

    # create custom action 'Close'

    new_ca_page = index_ca_page.new
    new_ca_page.set_name('Close')
    new_ca_page.add_action('Status', 'Close')
    new_ca_page.set_condition('Role', role.name)
    new_ca_page.create

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign', 'Close')

    # create custom action 'Escalate'
    new_ca_page = index_ca_page.new
    new_ca_page.set_name('Escalate')
    new_ca_page.add_action('Priority', immediate_priority.name)
    new_ca_page.add_action(list_custom_field.name, selected_list_custom_field_options.map(&:name))
    new_ca_page.create

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign', 'Close', 'Escalate')

    # create custom action 'Reset'

    new_ca_page = index_ca_page.new

    new_ca_page.set_name('Reset')
    new_ca_page.add_action('Priority', default_priority.name)
    new_ca_page.add_action('Status', default_status.name)
    new_ca_page.add_action('Assignee', user.name)
    new_ca_page.set_condition('Status', closed_status.name)
    new_ca_page.create

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign', 'Close', 'Escalate', 'Reset')

    # create custom action 'Other roles action'

    new_ca_page = index_ca_page.new

    new_ca_page.set_name('Other roles action')
    new_ca_page.add_action('Status', default_status.name)
    new_ca_page.set_condition('Role', other_role.name)
    new_ca_page.create

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign', 'Close', 'Escalate', 'Reset', 'Other roles action')

    # use custom actions
    login_as(user)

    wp_page.visit!

    expect(page)
      .to have_selector('.custom-action', text: 'Unassign')
    expect(page)
      .to have_selector('.custom-action', text: 'Close')
    expect(page)
      .to have_selector('.custom-action', text: 'Escalate')
    expect(page)
      .to have_no_selector('.custom-action', text: 'Reset')
    expect(page)
      .to have_no_selector('.custom-action', text: 'Other roles action')

    within('.custom-actions') do
      click_button('Unassign')
    end

    wp_page.expect_attributes assignee: '-'
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    ## Bump the lockVersion and by that force a conflict.
    WorkPackage.where(id: work_package.id).update_all(lock_version: 10)

    within('.custom-actions') do
      click_button('Escalate')
    end

    wp_page.expect_notification type: :error, message: I18n.t('api_v3.errors.code_409')

    wp_page.visit!

    within('.custom-actions') do
      click_button('Escalate')
    end

    wp_page.expect_attributes priority: immediate_priority.name,
                              status: default_status.name,
                              assignee: '-',
                              "customField#{list_custom_field.id}" => selected_list_custom_field_options.map(&:name).join(' ')
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    within('.custom-actions') do
      click_button('Close')
    end

    wp_page.expect_attributes status: closed_status.name,
                              priority: immediate_priority.name
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    expect(page)
      .to have_selector('.custom-action', text: 'Reset')

    within('.custom-actions') do
      click_button('Reset')
    end

    wp_page.expect_attributes priority: default_priority.name,
                              status: default_status.name,
                              assignee: user.name
    wp_page.expect_notification message: 'Successful update'

    # edit 'Reset' to now be named 'Reject' which sets the status to 'Rejected'
    login_as(admin)

    index_ca_page.visit!

    edit_ca_page = index_ca_page.edit('Reset')

    edit_ca_page.set_name 'Reject'
    edit_ca_page.remove_action 'Priority'
    edit_ca_page.set_action 'Assignee', '-'
    edit_ca_page.set_action 'Status', rejected_status.name
    edit_ca_page.set_condition 'Status', default_status.name
    edit_ca_page.save

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Unassign', 'Close', 'Escalate', 'Reject')

    # Check the altered button
    login_as(user)

    wp_page.visit!

    expect(page)
      .to have_selector('.custom-action', text: 'Unassign')
    expect(page)
      .to have_selector('.custom-action', text: 'Close')
    expect(page)
      .to have_selector('.custom-action', text: 'Escalate')
    expect(page)
      .to have_selector('.custom-action', text: 'Reject')
    expect(page)
      .to have_no_selector('.custom-action', text: 'Reset')

    within('.custom-actions') do
      click_button('Reject')
    end

    wp_page.expect_attributes assignee: '-',
                              status: rejected_status.name,
                              priority: default_priority.name
    wp_page.expect_notification message: 'Successful update'
    wp_page.dismiss_notification!

    expect(page)
      .to have_no_selector('.custom-action', text: 'Reject')

    # Delete 'Reject' from list of actions
    login_as(admin)

    index_ca_page.visit!

    index_ca_page.delete('Unassign')

    index_ca_page.expect_current_path
    index_ca_page.expect_listed('Close', 'Escalate', 'Reject')

    login_as(user)

    wp_page.visit!

    expect(page)
      .to have_no_selector('.custom-action', text: 'Unassign')
    expect(page)
      .to have_selector('.custom-action', text: 'Close')
    expect(page)
      .to have_selector('.custom-action', text: 'Escalate')
    expect(page)
      .to have_no_selector('.custom-action', text: 'Reject')
  end
end
