#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'roles_controller'

# Re-raise errors caught by the controller.
class RolesController; def rescue_action(e) raise e end; end

class RolesControllerTest < ActionController::TestCase
  fixtures :roles, :users, :members, :member_roles, :workflows, :trackers

  def setup
    @controller = RolesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_get_index
    get :index
    assert_response :success
    assert_template 'index'

    assert_not_nil assigns(:roles)
    assert_equal Role.find(:all, :order => 'builtin, position'), assigns(:roles)

    assert_tag :tag => 'a', :attributes => { :href => '/roles/edit/1' },
                            :content => 'Manager'
  end

  def test_get_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_post_new_with_validaton_failure
    post :new, :role => {:name => '',
                         :permissions => ['add_issues', 'edit_issues', 'log_time', ''],
                         :assignable => '0'}

    assert_response :success
    assert_template 'new'
    assert_tag :tag => 'div', :attributes => { :id => 'errorExplanation' }
  end

  def test_post_new_without_workflow_copy
    post :new, :role => {:name => 'RoleWithoutWorkflowCopy',
                         :permissions => ['add_issues', 'edit_issues', 'log_time', ''],
                         :assignable => '0'}

    assert_redirected_to '/roles'
    role = Role.find_by_name('RoleWithoutWorkflowCopy')
    assert_not_nil role
    assert_equal [:add_issues, :edit_issues, :log_time], role.permissions
    assert !role.assignable?
  end

  def test_post_new_with_workflow_copy
    post :new, :role => {:name => 'RoleWithWorkflowCopy',
                         :permissions => ['add_issues', 'edit_issues', 'log_time', ''],
                         :assignable => '0'},
               :copy_workflow_from => '1'

    assert_redirected_to '/roles'
    role = Role.find_by_name('RoleWithWorkflowCopy')
    assert_not_nil role
    assert_equal Role.find(1).workflows.size, role.workflows.size
  end

  def test_get_edit
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_equal Role.find(1), assigns(:role)
  end

  def test_post_edit
    post :edit, :id => 1,
                :role => {:name => 'Manager',
                          :permissions => ['edit_project', ''],
                          :assignable => '0'}

    assert_redirected_to '/roles'
    role = Role.find(1)
    assert_equal [:edit_project], role.permissions
  end

  def test_destroy
    r = Role.new(:name => 'ToBeDestroyed', :permissions => [:view_wiki_pages])
    assert r.save

    post :destroy, :id => r
    assert_redirected_to '/roles'
    assert_nil Role.find_by_id(r.id)
  end

  def test_destroy_role_in_use
    post :destroy, :id => 1
    assert_redirected_to '/roles'
    assert flash[:error] == 'This role is in use and cannot be deleted.'
    assert_not_nil Role.find_by_id(1)
  end

  def test_get_report
    get :report
    assert_response :success
    assert_template 'report'

    assert_not_nil assigns(:roles)
    assert_equal Role.find(:all, :order => 'builtin, position'), assigns(:roles)

    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'permissions[3][]',
                                                 :value => 'add_issues',
                                                 :checked => 'checked' }

    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'permissions[3][]',
                                                 :value => 'delete_issues',
                                                 :checked => nil }
  end

  def test_post_report
    post :report, :permissions => { '0' => '', '1' => ['edit_issues'], '3' => ['add_issues', 'delete_issues']}
    assert_redirected_to '/roles'

    assert_equal [:edit_issues], Role.find(1).permissions
    assert_equal [:add_issues, :delete_issues], Role.find(3).permissions
    assert Role.find(2).permissions.empty?
  end

  def test_clear_all_permissions
    post :report, :permissions => { '0' => '' }
    assert_redirected_to '/roles'
    assert Role.find(1).permissions.empty?
  end

  def test_move_highest
    post :edit, :id => 3, :role => {:move_to => 'highest'}
    assert_redirected_to '/roles'
    assert_equal 1, Role.find(3).position
  end

  def test_move_higher
    position = Role.find(3).position
    post :edit, :id => 3, :role => {:move_to => 'higher'}
    assert_redirected_to '/roles'
    assert_equal position - 1, Role.find(3).position
  end

  def test_move_lower
    position = Role.find(2).position
    post :edit, :id => 2, :role => {:move_to => 'lower'}
    assert_redirected_to '/roles'
    assert_equal position + 1, Role.find(2).position
  end

  def test_move_lowest
    post :edit, :id => 2, :role => {:move_to => 'lowest'}
    assert_redirected_to '/roles'
    assert_equal Role.count, Role.find(2).position
  end
end
