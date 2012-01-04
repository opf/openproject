#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < ActionController::TestCase
  fixtures :users, :roles

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
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

  def test_login
    get :login
    assert_template 'login'
  end

  def test_login_with_logged_account
    @request.session[:user_id] = 2
    get :login
    assert_redirected_to home_url
  end

  if Object.const_defined?(:OpenID)

  def test_login_with_openid_for_existing_user
    Setting.self_registration = '3'
    Setting.openid = '1'
    existing_user = User.new(:firstname => 'Cool',
                             :lastname => 'User',
                             :mail => 'user@somedomain.com',
                             :identity_url => 'http://openid.example.com/good_user')
    existing_user.login = 'cool_user'
    assert existing_user.save!

    post :login, :openid_url => existing_user.identity_url
    assert_redirected_to '/my/page'
  end

  def test_login_with_invalid_openid_provider
    Setting.self_registration = '0'
    Setting.openid = '1'
    post :login, :openid_url => 'http;//openid.example.com/good_user'
    assert_redirected_to home_url
  end

  def test_login_with_openid_for_existing_non_active_user
    Setting.self_registration = '2'
    Setting.openid = '1'
    existing_user = User.new(:firstname => 'Cool',
                             :lastname => 'User',
                             :mail => 'user@somedomain.com',
                             :identity_url => 'http://openid.example.com/good_user',
                             :status => User::STATUS_REGISTERED)
    existing_user.login = 'cool_user'
    assert existing_user.save!

    post :login, :openid_url => existing_user.identity_url
    assert_redirected_to '/login'
  end

  def test_login_with_openid_with_new_user_created
    Setting.self_registration = '3'
    Setting.openid = '1'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to '/my/account'
    user = User.find_by_login('cool_user')
    assert user
    assert_equal 'Cool', user.firstname
    assert_equal 'User', user.lastname
  end

  def test_login_with_openid_with_new_user_and_self_registration_off
    Setting.self_registration = '0'
    Setting.openid = '1'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to home_url
    user = User.find_by_login('cool_user')
    assert ! user
  end

  def test_login_with_openid_with_new_user_created_with_email_activation_should_have_a_token
    Setting.self_registration = '1'
    Setting.openid = '1'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to '/login'
    user = User.find_by_login('cool_user')
    assert user

    token = Token.find_by_user_id_and_action(user.id, 'register')
    assert token
  end

  def test_login_with_openid_with_new_user_created_with_manual_activation
    Setting.self_registration = '2'
    Setting.openid = '1'
    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_redirected_to '/login'
    user = User.find_by_login('cool_user')
    assert user
    assert_equal User::STATUS_REGISTERED, user.status
  end

  def test_login_with_openid_with_new_user_with_conflict_should_register
    Setting.self_registration = '3'
    Setting.openid = '1'
    existing_user = User.new(:firstname => 'Cool', :lastname => 'User', :mail => 'user@somedomain.com')
    existing_user.login = 'cool_user'
    assert existing_user.save!

    post :login, :openid_url => 'http://openid.example.com/good_user'
    assert_response :success
    assert_template 'register'
    assert assigns(:user)
    assert_equal 'http://openid.example.com/good_user', assigns(:user)[:identity_url]
  end

  def test_setting_openid_should_return_true_when_set_to_true
    Setting.openid = '1'
    assert_equal true, Setting.openid?
  end

  else
    puts "Skipping openid tests."
  end

  def test_logout
    @request.session[:user_id] = 2
    get :logout
    assert_redirected_to '/'
    assert_nil @request.session[:user_id]
  end

  context "GET #register" do
    context "with self registration on" do
      setup do
        Setting.self_registration = '3'
        get :register
      end

      should_respond_with :success
      should_render_template :register
      should_assign_to :user
    end

    context "with self registration off" do
      setup do
        Setting.self_registration = '0'
        get :register
      end

      should_redirect_to('/') { home_url }
    end
  end

  # See integration/account_test.rb for the full test
  context "POST #register" do
    context "with self registration on automatic" do
      setup do
        Setting.self_registration = '3'
        post :register, :user => {
          :login => 'register',
          :password => 'test',
          :password_confirmation => 'test',
          :firstname => 'John',
          :lastname => 'Doe',
          :mail => 'register@example.com'
        }
      end

      should_respond_with :redirect
      should_assign_to :user
      should_redirect_to('my page') { {:controller => 'my', :action => 'account'} }

      should_create_a_new_user { User.last(:conditions => {:login => 'register'}) }

      should 'set the user status to active' do
        user = User.last(:conditions => {:login => 'register'})
        assert user
        assert_equal User::STATUS_ACTIVE, user.status
      end
    end

    context "with self registration off" do
      setup do
        Setting.self_registration = '0'
        post :register
      end

      should_redirect_to('/') { home_url }
    end
  end

end
