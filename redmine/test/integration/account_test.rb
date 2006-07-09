# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

require "#{File.dirname(__FILE__)}/../test_helper"

class AccountTest < ActionController::IntegrationTest
  fixtures :users

  # Replace this with your real tests.
  def test_login
    get "account/my_page"
    assert_redirected_to "account/login"
    log_user('plochon', 'admin')
    
    get "account/my_account"
    assert_response :success
    assert_template "account/my_account"    
  end
  
  def test_change_password
    log_user('plochon', 'admin')
    get "account/my_account"
    assert_response :success
    assert_template "account/my_account" 
    
    post "account/change_password", :password => 'admin', :new_password => "hello", :new_password_confirmation => "hello2"
    assert_response :success
    assert_tag :tag => "div", :attributes => { :class => "errorExplanation" }
    
    post "account/change_password", :password => 'admiN', :new_password => "hello", :new_password_confirmation => "hello"
    assert_response :success
    assert_equal 'Wrong password', flash[:notice]
    
    post "account/change_password", :password => 'admin', :new_password => "hello", :new_password_confirmation => "hello"
    assert_response :success
    log_user('plochon', 'hello')    
  end
  
  def test_my_account
    log_user('plochon', 'admin')
    get "account/my_account"
    assert_response :success
    assert_template "account/my_account" 
    
    post "account/my_account", :user => {:firstname => "Joe", :login => "root", :admin => 1}
    assert_response :success
    assert_template "account/my_account" 
    user = User.find(2)
    assert_equal "Joe", user.firstname
    assert_equal "plochon", user.login
    assert_equal false, user.admin?
    
    log_user('plochon', 'admin')    
  end
  
  def test_my_page
    log_user('plochon', 'admin')
    get "account/my_page"
    assert_response :success
    assert_template "account/my_page"
  end
end
