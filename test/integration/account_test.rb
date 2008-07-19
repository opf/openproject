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

begin
  require 'mocha'
rescue
  # Won't run some tests
end

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
  
  def test_register_with_automatic_activation
    Setting.self_registration = '3'
    
    get 'account/register'
    assert_response :success
    assert_template 'account/register'
    
    post 'account/register', :user => {:login => "newuser", :language => "en", :firstname => "New", :lastname => "User", :mail => "newuser@foo.bar"}, 
                             :password => "newpass", :password_confirmation => "newpass"
    assert_redirected_to 'my/account'
    follow_redirect!
    assert_response :success
    assert_template 'my/account'
    
    assert User.find_by_login('newuser').active?
  end
  
  def test_register_with_manual_activation
    Setting.self_registration = '2'
    
    post 'account/register', :user => {:login => "newuser", :language => "en", :firstname => "New", :lastname => "User", :mail => "newuser@foo.bar"}, 
                             :password => "newpass", :password_confirmation => "newpass"
    assert_redirected_to 'account/login'
    assert !User.find_by_login('newuser').active?
  end
  
  def test_register_with_email_activation
    Setting.self_registration = '1'
    Token.delete_all
    
    post 'account/register', :user => {:login => "newuser", :language => "en", :firstname => "New", :lastname => "User", :mail => "newuser@foo.bar"}, 
                             :password => "newpass", :password_confirmation => "newpass"
    assert_redirected_to 'account/login'
    assert !User.find_by_login('newuser').active?
    
    token = Token.find(:first)
    assert_equal 'register', token.action
    assert_equal 'newuser@foo.bar', token.user.mail
    assert !token.expired?
    
    get 'account/activate', :token => token.value
    assert_redirected_to 'account/login'
    log_user('newuser', 'newpass')
  end
  
  if Object.const_defined?(:Mocha)
  
  def test_onthefly_registration
    # disable registration
    Setting.self_registration = '0'
    AuthSource.expects(:authenticate).returns([:login => 'foo', :firstname => 'Foo', :lastname => 'Smith', :mail => 'foo@bar.com', :auth_source_id => 66])
  
    post 'account/login', :username => 'foo', :password => 'bar'
    assert_redirected_to 'my/page'
    
    user = User.find_by_login('foo')
    assert user.is_a?(User)
    assert_equal 66, user.auth_source_id
    assert user.hashed_password.blank?
  end
  
  def test_onthefly_registration_with_invalid_attributes
    # disable registration
    Setting.self_registration = '0'
    AuthSource.expects(:authenticate).returns([:login => 'foo', :lastname => 'Smith', :auth_source_id => 66])
    
    post 'account/login', :username => 'foo', :password => 'bar'
    assert_response :success
    assert_template 'account/register'
    assert_tag :input, :attributes => { :name => 'user[firstname]', :value => '' }
    assert_tag :input, :attributes => { :name => 'user[lastname]', :value => 'Smith' }
    assert_no_tag :input, :attributes => { :name => 'user[login]' }
    assert_no_tag :input, :attributes => { :name => 'user[password]' }
    
    post 'account/register', :user => {:firstname => 'Foo', :lastname => 'Smith', :mail => 'foo@bar.com'}
    assert_redirected_to 'my/account'
    
    user = User.find_by_login('foo')
    assert user.is_a?(User)
    assert_equal 66, user.auth_source_id
    assert user.hashed_password.blank?
  end
  
  else
    puts 'Mocha is missing. Skipping tests.'
  end
end
