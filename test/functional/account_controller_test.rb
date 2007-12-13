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
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  fixtures :users
  
  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show
    get :show, :id => 2
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)
  end
  
  def test_show_inactive
    get :show, :id => 5
    assert_response 404
    assert_nil assigns(:user)
  end
  
  def test_login_with_wrong_password
    post :login, :login => 'admin', :password => 'bad'
    assert_response :success
    assert_template 'login'
    assert_tag 'div',
               :attributes => { :class => "flash error" },
               :content => /Invalid user or password/
  end
  
  def test_autologin
    Setting.autologin = "7"
    Token.delete_all
    post :login, :login => 'admin', :password => 'admin', :autologin => 1
    assert_redirected_to 'my/page'
    token = Token.find :first
    assert_not_nil token
    assert_equal User.find_by_login('admin'), token.user
    assert_equal 'autologin', token.action
  end
  
  def test_logout
    @request.session[:user_id] = 2
    get :logout
    assert_redirected_to ''
    assert_nil @request.session[:user_id]
  end
end
