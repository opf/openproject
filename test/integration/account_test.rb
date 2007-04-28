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

require "#{File.dirname(__FILE__)}/../test_helper"

class AccountTest < ActionController::IntegrationTest
  fixtures :users

  # Replace this with your real tests.
  def test_login
    get "my/page"
    assert_redirected_to "account/login"
    log_user('jsmith', 'jsmith')
    
    get "my/account"
    assert_response :success
    assert_template "my/account"    
  end
  
  def test_lost_password
    Token.delete_all
    
    get "account/lost_password"
    assert_response :success
    assert_template "account/lost_password"
    
    post "account/lost_password", :mail => 'jsmith@somenet.foo'
    assert_redirected_to "account/login"
    
    token = Token.find(:first)
    assert_equal 'recovery', token.action
    assert_equal 'jsmith@somenet.foo', token.user.mail
    assert !token.expired?
    
    get "account/lost_password", :token => token.value
    assert_response :success
    assert_template "account/password_recovery"
    
    post "account/lost_password", :token => token.value, :new_password => 'newpass', :new_password_confirmation => 'newpass'
    assert_redirected_to "account/login"
    assert_equal 'Password was successfully updated.', flash[:notice]
    
    log_user('jsmith', 'newpass')
    assert_equal 0, Token.count    
  end    
end
