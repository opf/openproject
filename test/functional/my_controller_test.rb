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
require 'my_controller'

# Re-raise errors caught by the controller.
class MyController; def rescue_action(e) raise e end; end

class MyControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = MyController.new
    @request    = ActionController::TestRequest.new
    @request.session[:user_id] = 2
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'page'
  end
  
  def test_page
    get :page
    assert_response :success
    assert_template 'page'
  end
  
  def test_get_account
    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)
  end

  def test_update_account
    post :account, :user => {:firstname => "Joe", :login => "root", :admin => 1}
    assert_redirected_to 'my/account'
    user = User.find(2)
    assert_equal user, assigns(:user)
    assert_equal "Joe", user.firstname
    assert_equal "jsmith", user.login
    assert !user.admin?
  end
  
  def test_change_password
    get :password
    assert_response :success
    assert_template 'password'
    
    # non matching password confirmation
    post :password, :password => 'jsmith', 
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello2'
    assert_response :success
    assert_template 'password'
    assert_tag :tag => "div", :attributes => { :class => "errorExplanation" }
    
    # wrong password
    post :password, :password => 'wrongpassword', 
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello'
    assert_response :success
    assert_template 'password'
    assert_equal 'Wrong password', flash[:error]
    
    # good password
    post :password, :password => 'jsmith',
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello'
    assert_redirected_to 'my/account'
    assert User.try_to_login('jsmith', 'hello')
  end
end
