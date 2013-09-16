#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_get_bulk_edit
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_tag :input, :attributes => {:name => 'issue[parent_id]'}

    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert_equal 'date', field.field_format
    assert_tag :input, :attributes => {:name => 'issue[custom_field_values][9]'}

    # System wide custom field
    assert CustomField.find(1).is_for_all?
    assert_tag :select, :attributes => {:name => 'issue[custom_field_values][1]'}
  end

  def test_get_bulk_edit_on_different_projects
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2, 6]
    assert_response :success
    assert_template 'bulk_edit'

    # Can not set issues from different projects as children of an issue
    assert_no_tag :input, :attributes => {:name => 'issue[parent_id]'}

    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert !field.project_ids.include?(WorkPackage.find(6).project_id)
    assert_no_tag :input, :attributes => {:name => 'issue[custom_field_values][9]'}
  end

  def test_bulk_update
    issue = WorkPackage.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing',
                                      :issue => { :priority_id => 7,
                                                  :assigned_to_id => '',
                                                  :custom_field_values => {'2' => ''} }

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], WorkPackage.find_all_by_id([1, 2]).collect {|i| i.priority.id}

    issue.reload
    journal = issue.journals.reorder('created_at DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bullk_update_should_not_send_a_notification_if_send_notification_is_off
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    put(:bulk_update,
         {
           :ids => [1, 2],
           :issue => {
             :priority_id => 7,
             :assigned_to_id => '',
             :custom_field_values => {'2' => ''}
           },
           :notes => 'Bulk editing',
           :send_notification => '0'
         })

    assert_response 302
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_bulk_update_on_different_projects
    issue = WorkPackage.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2, 6], :notes => 'Bulk editing',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7, 7], WorkPackage.find([1,2,6]).map(&:priority_id)

    issue.reload
    journal = issue.journals.reorder('created_at DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bulk_update_on_different_projects_without_rights
    Journal.delete_all

    @request.session[:user_id] = 3
    user = User.find(3)
    action = { :controller => "issues", :action => "bulk_update" }
    assert user.allowed_to?(action, WorkPackage.find(1).project)
    assert ! user.allowed_to?(action, WorkPackage.find(6).project)
    put :bulk_update, :ids => [1, 6], :notes => 'Bulk should fail',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}
    assert_response 403
    assert Journal.all.empty?
  end

  def test_bulk_update_should_send_a_notification
    WorkPackage.find(1).recreate_initial_journal!
    WorkPackage.find(2).recreate_initial_journal!

    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    put(:bulk_update,
         {
           :ids => [1, 2],
           :notes => 'Bulk editing',
           :issue => {
             :priority_id => 7,
             :assigned_to_id => '',
             :custom_field_values => {'2' => ''}
           }
         })

    assert_response 302
    assert_equal 5, ActionMailer::Base.deliveries.size
  end

  def test_bulk_update_status
    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing status',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :status_id => '5'}

    assert_response 302
    issue = WorkPackage.find(1)
    assert issue.closed?
  end

  def test_bulk_update_parent_id
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1, 3],
      :notes => 'Bulk editing parent',
      :issue => {:priority_id => '', :assigned_to_id => '', :status_id => '', :parent_id => '2'}

    assert_response 302
    parent = WorkPackage.find(2)
    assert_equal parent.id, WorkPackage.find(1).parent_id
    assert_equal parent.id, WorkPackage.find(3).parent_id
    assert_equal [1, 3], parent.children.collect(&:id).sort
  end

  def test_bulk_update_custom_field
    issue = WorkPackage.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => '777'}}

    assert_response 302

    issue.reload
    journal = issue.journals.last
    assert_equal '777', issue.custom_value_for(2).value
    assert_equal 1, journal.details.size
    assert_equal '125', journal.old_value_for(:custom_fields_2)
    assert_equal '777', journal.new_value_for(:custom_fields_2)
  end

  def test_bulk_update_unassign
    assert_not_nil WorkPackage.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk unassigning', :issue => {:assigned_to_id => 'none'}
    assert_response 302
    # check that the issues were updated
    assert_nil WorkPackage.find(2).assigned_to
  end

  def test_post_bulk_update_should_allow_fixed_version_to_be_set_to_a_subproject
    @request.session[:user_id] = 2

    put :bulk_update, :ids => [1,2], :issue => {:fixed_version_id => 4}

    assert_response :redirect
    issues = WorkPackage.find([1,2])
    issues.each do |issue|
      assert_equal 4, issue.fixed_version_id
      assert_not_equal issue.project_id, issue.fixed_version.project_id
    end
  end

  def test_post_bulk_update_should_redirect_back_using_the_back_url_parameter
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1,2], :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_post_bulk_update_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1,2], :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'work_packages', :action => 'index', :project_id => Project.find(1).identifier
  end
end
