# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'
require 'roles_controller'

# Re-raise errors caught by the controller.
class RolesController; def rescue_action(e) raise e end; end

class RolesControllerTest < Test::Unit::TestCase
  fixtures :roles, :users, :members, :workflows
  
  def setup
    @controller = RolesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
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
    
    assert_redirected_to 'roles/list'
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
    
    assert_redirected_to 'roles/list'
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
    
    assert_redirected_to 'roles/list'
    role = Role.find(1)
    assert_equal [:edit_project], role.permissions
  end
end
