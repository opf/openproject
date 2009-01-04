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
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  fixtures :users, :projects, :members
  
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:users)
    # active users only
    assert_nil assigns(:users).detect {|u| !u.active?}
  end
  
  def test_list_with_name_filter
    get :list, :name => 'john'
    assert_response :success
    assert_template 'list'
    users = assigns(:users)
    assert_not_nil users
    assert_equal 1, users.size
    assert_equal 'John', users.first.firstname
  end
  
  def test_edit_membership
    post :edit_membership, :id => 2, :membership_id => 1,
                           :membership => { :role_id => 2}
    assert_redirected_to '/users/edit/2?tab=memberships'
    assert_equal 2, Member.find(1).role_id
  end
  
  def test_destroy_membership
    post :destroy_membership, :id => 2, :membership_id => 1
    assert_redirected_to '/users/edit/2?tab=memberships'
    assert_nil Member.find_by_id(1)
  end
end
