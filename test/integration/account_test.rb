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

begin
  require 'mocha'
rescue
  # Won't run some tests
end

class AccountTest < ActionController::IntegrationTest
  fixtures :users, :roles

  # Replace this with your real tests.
  def test_login
    get "my/page"
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2Fmy%2Fpage"
    log_user('jsmith', 'jsmith')

    get "my/account"
    assert_response :success
    assert_template "my/account"
  end

  def test_autologin
    user = User.find(1)
    Setting.autologin = "7"
    Token.delete_all

    # User logs in with 'autologin' checked
    post '/login', :username => user.login, :password => 'admin', :autologin => 1
    assert_redirected_to '/my/page'
    token = Token.find :first
    assert_not_nil token
    assert_equal user, token.user
    assert_equal 'autologin', token.action
    assert_equal user.id, session[:user_id]
    assert_equal token.value, cookies[Redmine::Configuration['autologin_cookie_name']]

    # Session is cleared
    reset!
    User.current = nil
    # Clears user's last login timestamp
    user.update_attribute :last_login_on, nil
    assert_nil user.reload.last_login_on

    # User comes back with his autologin cookie
    cookies[Redmine::Configuration['autologin_cookie_name']] = token.value
    get '/my/page'
    assert_response :success
    assert_template 'my/page'
    assert_equal user.id, session[:user_id]
    assert_not_nil user.reload.last_login_on
    assert user.last_login_on.utc > 10.second.ago.utc
  end

  def test_lost_password
    Token.delete_all

    get "account/lost_password"
    assert_response :success
    assert_template "account/lost_password"

    post "account/lost_password", :mail => 'jSmith@somenet.foo'
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2F"

    token = Token.find(:first)
    assert_equal 'recovery', token.action
    assert_equal 'jsmith@somenet.foo', token.user.mail
    assert !token.expired?

    get "account/lost_password", :token => token.value
    assert_response :success
    assert_template "account/password_recovery"

    post "account/lost_password", :token => token.value, :new_password => 'newpass', :new_password_confirmation => 'newpass'
    assert_redirected_to "/login"
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
    assert_redirected_to '/my/account'
    follow_redirect!
    assert_response :success
    assert_template 'my/account'

    user = User.find_by_login('newuser')
    assert_not_nil user
    assert user.active?
    assert_not_nil user.last_login_on
  end

  def test_register_with_manual_activation
    Setting.self_registration = '2'

    post 'account/register', :user => {:login => "newuser", :language => "en", :firstname => "New", :lastname => "User", :mail => "newuser@foo.bar"},
                             :password => "newpass", :password_confirmation => "newpass"
    assert_redirected_to '/login'
    assert !User.find_by_login('newuser').active?
  end

  def test_register_with_email_activation
    Setting.self_registration = '1'
    Token.delete_all

    post 'account/register', :user => {:login => "newuser", :language => "en", :firstname => "New", :lastname => "User", :mail => "newuser@foo.bar"},
                             :password => "newpass", :password_confirmation => "newpass"
    assert_redirected_to '/login'
    assert !User.find_by_login('newuser').active?

    token = Token.find(:first)
    assert_equal 'register', token.action
    assert_equal 'newuser@foo.bar', token.user.mail
    assert !token.expired?

    get 'account/activate', :token => token.value
    assert_redirected_to '/login'
    log_user('newuser', 'newpass')
  end

  should_eventually "login after losing password should redirect back to home" do
    visit "/login"
    assert_response :success

    click_link "Lost password"
    assert_response :success

    # Lost password form
    fill_in "mail", :with => "admin@somenet.foo"
    click_button "Submit"

    assert_response :success # back to login page
    assert_equal "/login", current_path

    fill_in "Login:", :with => 'admin'
    fill_in "Password:", :with => 'test'
    click_button "login"

    assert_response :success
    assert_equal "/", current_path

  end


  if Object.const_defined?(:Mocha)

  def test_onthefly_registration
    # disable registration
    Setting.self_registration = '0'
    AuthSource.expects(:authenticate).returns({:login => 'foo', :firstname => 'Foo', :lastname => 'Smith', :mail => 'foo@bar.com', :auth_source_id => 66})

    post 'account/login', :username => 'foo', :password => 'bar'
    assert_redirected_to '/my/page'

    user = User.find_by_login('foo')
    assert user.is_a?(User)
    assert_equal 66, user.auth_source_id
    assert user.hashed_password.blank?
  end

  def test_onthefly_registration_with_invalid_attributes
    # disable registration
    Setting.self_registration = '0'
    AuthSource.expects(:authenticate).returns({:login => 'foo', :lastname => 'Smith', :auth_source_id => 66})

    post 'account/login', :username => 'foo', :password => 'bar'
    assert_response :success
    assert_template 'account/register'
    assert_tag :input, :attributes => { :name => 'user[firstname]', :value => '' }
    assert_tag :input, :attributes => { :name => 'user[lastname]', :value => 'Smith' }
    assert_no_tag :input, :attributes => { :name => 'user[login]' }
    assert_no_tag :input, :attributes => { :name => 'user[password]' }

    post 'account/register', :user => {:firstname => 'Foo', :lastname => 'Smith', :mail => 'foo@bar.com'}
    assert_redirected_to '/my/account'

    user = User.find_by_login('foo')
    assert user.is_a?(User)
    assert_equal 66, user.auth_source_id
    assert user.hashed_password.blank?
  end

  def test_login_and_logout_should_clear_session
    get '/login'
    sid = session[:session_id]

    post '/login', :username => 'admin', :password => 'admin'
    assert_redirected_to '/my/page'
    assert_not_equal sid, session[:session_id], "login should reset session"
    assert_equal 1, session[:user_id]
    sid = session[:session_id]

    get '/'
    assert_equal sid, session[:session_id]

    get '/logout'
    assert_not_equal sid, session[:session_id], "logout should reset session"
    assert_nil session[:user_id]
  end

  else
    puts 'Mocha is missing. Skipping tests.'
  end
end
