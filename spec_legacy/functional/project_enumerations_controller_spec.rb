#-- encoding: UTF-8

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

require_relative '../legacy_spec_helper'

describe ProjectEnumerationsController, type: :controller do
  fixtures :all

  before do
    session[:user_id] = nil
    Setting.default_language = 'en'
  end

  it 'update to override system activities' do
    session[:user_id] = 2 # manager
    billable_field = TimeEntryActivityCustomField.find_by(name: 'Billable')

    params = {
      project_id: 1,
      enumerations: {
        # Design, De-activate
        '9' => { 'parent_id' => '9', 'custom_field_values' => { '7' => '1' }, 'active' => '0' },
        # Development, Change custom value
        '10' => { 'parent_id' => '10', 'custom_field_values' => { '7' => '0' }, 'active' => '1' },
        # Inactive Activity, Activate with custom value
        '14' => { 'parent_id' => '14', 'custom_field_values' => { '7' => '1' }, 'active' => '1' },
        '11' => { 'parent_id' => '11', 'custom_field_values' => { '7' => '1' }, 'active' => '1' } # QA, no changes
      }
    }

    put :update, params: params

    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')

    # ... Design
    design = project.time_entry_activities.find_by(name: 'Design')
    assert design, 'Project activity not found'

    assert_equal 9, design.parent_id # Relate to the system activity
    refute_equal design.parent.id, design.id # Different records
    assert_equal design.parent.name, design.name # Same name
    assert !design.active?

    # ... Development
    development = project.time_entry_activities.find_by(name: 'Development')
    assert development, 'Project activity not found'

    assert_equal 10, development.parent_id # Relate to the system activity
    refute_equal development.parent.id, development.id # Different records
    assert_equal development.parent.name, development.name # Same name
    assert development.active?
    assert_equal 'f', development.custom_value_for(billable_field).value

    # ... Inactive Activity
    previously_inactive = project.time_entry_activities.find_by(name: 'Inactive Activity')
    assert previously_inactive, 'Project activity not found'

    assert_equal 14, previously_inactive.parent_id # Relate to the system activity
    refute_equal previously_inactive.parent.id, previously_inactive.id # Different records
    assert_equal previously_inactive.parent.name, previously_inactive.name # Same name
    assert previously_inactive.active?
    assert_equal 't', previously_inactive.custom_value_for(billable_field).value

    # ... QA
    assert_equal nil, project.time_entry_activities.find_by(name: 'QA'), "Custom QA activity created when it wasn't modified"
  end

  it 'update will update project specific activities' do
    session[:user_id] = 2 # manager

    project_activity = TimeEntryActivity.new(
      name: 'Project Specific',
      parent: TimeEntryActivity.first,
      project: Project.find(1),
      active: true
    )
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new(
      name: 'Project Specific Two',
      parent: TimeEntryActivity.last,
      project: Project.find(1),
      active: true
    )
    assert project_activity_two.save

    params = {
      project_id: 1,
      enumerations: {
        project_activity.id => { 'custom_field_values' => { '7' => '1' }, 'active' => '0' }, # De-activate
        project_activity_two.id => { 'custom_field_values' => { '7' => '1' }, 'active' => '0' } # De-activate
      }
    }

    put :update, params: params

    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')
    assert_equal 2, project.time_entry_activities.count

    activity_one = project.time_entry_activities.find_by(name: project_activity.name)
    assert activity_one, 'Project activity not found'
    assert_equal project_activity.id, activity_one.id
    assert !activity_one.active?

    activity_two = project.time_entry_activities.find_by(name: project_activity_two.name)
    assert activity_two, 'Project activity not found'
    assert_equal project_activity_two.id, activity_two.id
    assert !activity_two.active?
  end

  it 'update when creating new activities will convert existing data' do
    assert_equal 3, TimeEntry.where(activity_id: 9, project_id: 1).size

    session[:user_id] = 2 # manager

    params = {
      project_id: 1,
      enumerations: {
        '9' => { 'parent_id' => '9', 'custom_field_values' => { '7' => '1' }, 'active' => '0' } # Design, De-activate
      }
    }
    put :update, params: params

    assert_response :redirect

    # No more TimeEntries using the system activity
    assert_equal 0, TimeEntry.where(activity_id: 9, project_id: 1).size, 'Time Entries still assigned to system activities'
    # All TimeEntries using project activity
    project_specific_activity = TimeEntryActivity.find_by(parent_id: 9, project_id: 1)
    assert_equal 3,
                 TimeEntry.where(activity_id: project_specific_activity.id, project_id: 1).size,
                 'No Time Entries assigned to the project activity'
  end

  it 'update when creating new activities will not convert existing data if an exception is raised' do
    # TODO: Need to cause an exception on create but these tests
    # aren't setup for mocking.  Just create a record now so the
    # second one is a duplicate
    # parent = TimeEntryActivity.find(9)
    parent = TimeEntryActivity.new
    parent.attributes = { name: parent.name, project_id: 1, position: parent.position, active: true }
    parent.save(validate: false)

    project = Project.find(1)
    project.time_entries.create!(hours: 1.0,
                                 user: User.find(1),
                                 work_package_id: 3,
                                 activity_id: 10,
                                 spent_on: '2009-01-01')

    assert_equal 3, TimeEntry.where(activity_id: 9, project_id: 1).size
    assert_equal 1, TimeEntry.where(activity_id: 10, project_id: 1).size

    session[:user_id] = 2 # manager

    params = {
      project_id: 1,
      enumerations: {
        '9' => { 'parent_id' => parent.id,
                 'custom_field_values' => { '7' => '1' },
                 'active' => '0' }
      }
    }

    put :update, params: params

    assert_response :redirect

    # TimeEntries shouldn't have been reassigned on the failed record
    assert_equal 3,
                 TimeEntry.where(activity_id: 9, project_id: 1).size,
                 'Time Entries are not assigned to system activities'
    # TimeEntries shouldn't have been reassigned on the saved record either
    assert_equal 1,
                 TimeEntry.where(activity_id: 10, project_id: 1).size,
                 'Time Entries are not assigned to system activities'
  end

  it 'destroy' do
    session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new(
      name: 'Project Specific',
      parent: TimeEntryActivity.first,
      project: Project.find(1),
      active: true
    )
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new(
      name: 'Project Specific Two',
      parent: TimeEntryActivity.last,
      project: Project.find(1),
      active: true
    )
    assert project_activity_two.save

    delete :destroy, params: { project_id: 1 }
    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by(id: project_activity.id)
    assert_nil TimeEntryActivity.find_by(id: project_activity_two.id)
  end

  it 'destroy should reassign time entries back to the system activity' do
    session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new(
      name: 'Project Specific Design',
      parent: TimeEntryActivity.find(9),
      project: Project.find(1),
      active: true
    )
    assert project_activity.save
    assert TimeEntry.where(['project_id = ? AND activity_id = ?', 1, 9])
      .update_all("activity_id = '#{project_activity.id}'")
    assert_equal 3, TimeEntry.where(activity_id: project_activity.id, project_id: 1).size

    delete :destroy, params: { project_id: 1 }
    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by(id: project_activity.id)
    assert_equal 0,
                 TimeEntry.where(activity_id: project_activity.id, project_id: 1).size,
                 'TimeEntries still assigned to project specific activity'
    assert_equal 3,
                 TimeEntry.where(activity_id: 9, project_id: 1).size,
                 'TimeEntries still assigned to project specific activity'
  end
end
