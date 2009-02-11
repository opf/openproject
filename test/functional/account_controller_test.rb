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
  fixtures :users, :roles
  
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
  
  def test_login_should_redirect_to_back_url_param
    # request.uri is "test.host" in test environment
    post :login, :username => 'jsmith', :password => 'jsmith', :back_url => 'http%3A%2F%2Ftest.host%2Fissues%2Fshow%2F1'
    assert_redirected_to '/issues/show/1'
  end
  
  def test_login_should_not_redirect_to_another_host
    post :login, :username => 'jsmith', :password => 'jsmith', :back_url => 'http%3A%2F%2Ftest.foo%2Ffake'
    assert_redirected_to '/my/page'
  end

  def test_login_with_wrong_password
    post :login, :username => 'admin', :password => 'bad'
    assert_response :success
    assert_template 'login'
    assert_tag 'div',
               :attributes => { :class => "flash error" },
               :content => /Invalid user or password/
  end
  
  def test_login_with_openid
    Setting.self_registration = '3'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to 'my/page'
  end

  def test_login_with_openid_with_new_user_created
    Setting.self_registration = '3'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to 'my/page'
    user = User.find_by_login('cool_user')
    assert user
    assert_equal 'Cool', user.firstname
    assert_equal 'User', user.lastname
  end
  
  def test_login_with_openid_with_new_user_created_with_email_activation_should_have_a_token
    Setting.self_registration = '1'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to 'login'
    user = User.find_by_login('cool_user')
    assert user

    token = Token.find_by_user_id_and_action(user.id, 'register')
    assert token
  end
  
  def test_login_with_openid_with_new_user_created_with_manual_activation
    Setting.self_registration = '2'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to 'login'
    user = User.find_by_login('cool_user')
    assert user
    assert_equal User::STATUS_REGISTERED, user.status
  end
  
  def test_login_with_openid_with_new_user_with_conflict_should_register
    Setting.self_registration = '3'
    existing_user = User.new(:firstname => 'Cool', :lastname => 'User', :mail => 'user@somedomain.com')
    existing_user.login = 'cool_user'
    assert existing_user.save!
    
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_response :success
    assert_template 'register'
    assert assigns(:user)
    assert_equal 'http://openid.example.com/good_user', assigns(:user)[:identity_url]
  end
  
  def test_autologin
    Setting.autologin = "7"
    Token.delete_all
    post :login, :username => 'admin', :password => 'admin', :autologin => 1
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
