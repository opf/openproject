#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class ProjectEnumerationsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end

  def test_update_to_override_system_activities
    @request.session[:user_id] = 2 # manager
    billable_field = TimeEntryActivityCustomField.find_by_name("Billable")

    put :update, :project_id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # Design, De-activate
      "10"=> {"parent_id"=>"10", "custom_field_values"=>{"7"=>"0"}, "active"=>"1"}, # Development, Change custom value
      "14"=>{"parent_id"=>"14", "custom_field_values"=>{"7"=>"1"}, "active"=>"1"}, # Inactive Activity, Activate with custom value
      "11"=>{"parent_id"=>"11", "custom_field_values"=>{"7"=>"1"}, "active"=>"1"} # QA, no changes
    }

    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')

    # ... Design
    design = project.time_entry_activities.find_by_name("Design")
    assert design, "Project activity not found"

    assert_equal 9, design.parent_id # Relate to the system activity
    assert_not_equal design.parent.id, design.id # Different records
    assert_equal design.parent.name, design.name # Same name
    assert !design.active?

    # ... Development
    development = project.time_entry_activities.find_by_name("Development")
    assert development, "Project activity not found"

    assert_equal 10, development.parent_id # Relate to the system activity
    assert_not_equal development.parent.id, development.id # Different records
    assert_equal development.parent.name, development.name # Same name
    assert development.active?
    assert_equal "0", development.custom_value_for(billable_field).value

    # ... Inactive Activity
    previously_inactive = project.time_entry_activities.find_by_name("Inactive Activity")
    assert previously_inactive, "Project activity not found"

    assert_equal 14, previously_inactive.parent_id # Relate to the system activity
    assert_not_equal previously_inactive.parent.id, previously_inactive.id # Different records
    assert_equal previously_inactive.parent.name, previously_inactive.name # Same name
    assert previously_inactive.active?
    assert_equal "1", previously_inactive.custom_value_for(billable_field).value

    # ... QA
    assert_equal nil, project.time_entry_activities.find_by_name("QA"), "Custom QA activity created when it wasn't modified"
  end

  def test_update_will_update_project_specific_activities
    @request.session[:user_id] = 2 # manager

    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific',
                                               :parent => TimeEntryActivity.find(:first),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new({
                                                   :name => 'Project Specific Two',
                                                   :parent => TimeEntryActivity.find(:last),
                                                   :project => Project.find(1),
                                                   :active => true
                                                 })
    assert project_activity_two.save


    put :update, :project_id => 1, :enumerations => {
      project_activity.id => {"custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # De-activate
      project_activity_two.id => {"custom_field_values"=>{"7" => "1"}, "active"=>"0"} # De-activate
    }

    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')
    assert_equal 2, project.time_entry_activities.count

    activity_one = project.time_entry_activities.find_by_name(project_activity.name)
    assert activity_one, "Project activity not found"
    assert_equal project_activity.id, activity_one.id
    assert !activity_one.active?

    activity_two = project.time_entry_activities.find_by_name(project_activity_two.name)
    assert activity_two, "Project activity not found"
    assert_equal project_activity_two.id, activity_two.id
    assert !activity_two.active?
  end

  def test_update_when_creating_new_activities_will_convert_existing_data
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size

    @request.session[:user_id] = 2 # manager
    put :update, :project_id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"} # Design, De-activate
    }
    assert_response :redirect

    # No more TimeEntries using the system activity
    assert_equal 0, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "Time Entries still assigned to system activities"
    # All TimeEntries using project activity
    project_specific_activity = TimeEntryActivity.find_by_parent_id_and_project_id(9, 1)
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(project_specific_activity.id, 1).size, "No Time Entries assigned to the project activity"
  end

  def test_update_when_creating_new_activities_will_not_convert_existing_data_if_an_exception_is_raised
    # TODO: Need to cause an exception on create but these tests
    # aren't setup for mocking.  Just create a record now so the
    # second one is a dupicate
    parent = TimeEntryActivity.find(9)
    TimeEntryActivity.create!({:name => parent.name, :project_id => 1, :position => parent.position, :active => true})
    TimeEntry.create!({:project_id => 1, :hours => 1.0, :user => User.find(1), :issue_id => 3, :activity_id => 10, :spent_on => '2009-01-01'})

    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size
    assert_equal 1, TimeEntry.find_all_by_activity_id_and_project_id(10, 1).size

    @request.session[:user_id] = 2 # manager
    put :update, :project_id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # Design
      "10"=> {"parent_id"=>"10", "custom_field_values"=>{"7"=>"0"}, "active"=>"1"} # Development, Change custom value
    }
    assert_response :redirect

    # TimeEntries shouldn't have been reassigned on the failed record
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "Time Entries are not assigned to system activities"
    # TimeEntries shouldn't have been reassigned on the saved record either
    assert_equal 1, TimeEntry.find_all_by_activity_id_and_project_id(10, 1).size, "Time Entries are not assigned to system activities"
  end

  def test_destroy
    @request.session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific',
                                               :parent => TimeEntryActivity.find(:first),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new({
                                                   :name => 'Project Specific Two',
                                                   :parent => TimeEntryActivity.find(:last),
                                                   :project => Project.find(1),
                                                   :active => true
                                                 })
    assert project_activity_two.save

    delete :destroy, :project_id => 1
    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by_id(project_activity.id)
    assert_nil TimeEntryActivity.find_by_id(project_activity_two.id)
  end

  def test_destroy_should_reassign_time_entries_back_to_the_system_activity
    @request.session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific Design',
                                               :parent => TimeEntryActivity.find(9),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    assert TimeEntry.update_all("activity_id = '#{project_activity.id}'", ["project_id = ? AND activity_id = ?", 1, 9])
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(project_activity.id, 1).size

    delete :destroy, :project_id => 1
    assert_response :redirect
    assert_redirected_to '/projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by_id(project_activity.id)
    assert_equal 0, TimeEntry.find_all_by_activity_id_and_project_id(project_activity.id, 1).size, "TimeEntries still assigned to project specific activity"
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "TimeEntries still assigned to project specific activity"
  end

end
