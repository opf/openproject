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
require 'my_controller'

# Re-raise errors caught by the controller.
class MyController; def rescue_action(e) raise e end; end

class MyControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :issues, :issue_statuses, :trackers, :enumerations, :custom_fields

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

  def test_my_account_should_show_editable_custom_fields
    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)

    assert_tag :input, :attributes => { :name => 'user[custom_field_values][4]'}
  end

  def test_my_account_should_not_show_non_editable_custom_fields
    UserCustomField.find(4).update_attribute :editable, false

    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)

    assert_no_tag :input, :attributes => { :name => 'user[custom_field_values][4]'}
  end

  def test_update_account
    post :account,
      :user => {
        :firstname => "Joe",
        :login => "root",
        :admin => 1,
        :group_ids => ['10'],
        :custom_field_values => {"4" => "0100562500"}
      }

    assert_redirected_to '/my/account'
    user = User.find(2)
    assert_equal user, assigns(:user)
    assert_equal "Joe", user.firstname
    assert_equal "jsmith", user.login
    assert_equal "0100562500", user.custom_value_for(4).value
    # ignored
    assert !user.admin?
    assert user.groups.empty?
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
    assert_redirected_to '/my/account'
    assert User.try_to_login('jsmith', 'hello')
  end

  def test_page_layout
    get :page_layout
    assert_response :success
    assert_template 'page_layout'
  end

  def test_add_block
    xhr :post, :add_block, :block => 'issuesreportedbyme'
    assert_response :success
    assert User.find(2).pref[:my_page_layout]['top'].include?('issuesreportedbyme')
  end

  def test_remove_block
    xhr :post, :remove_block, :block => 'issuesassignedtome'
    assert_response :success
    assert !User.find(2).pref[:my_page_layout].values.flatten.include?('issuesassignedtome')
  end

  def test_order_blocks
    xhr :post, :order_blocks, :group => 'left', 'list-left' => ['documents', 'calendar', 'latestnews']
    assert_response :success
    assert_equal ['documents', 'calendar', 'latestnews'], User.find(2).pref[:my_page_layout]['left']
  end

  context "POST to reset_rss_key" do
    context "with an existing rss_token" do
      setup do
        @previous_token_value = User.find(2).rss_key # Will generate one if it's missing
        post :reset_rss_key
      end

      should "destroy the existing token" do
        assert_not_equal @previous_token_value, User.find(2).rss_key
      end

      should "create a new token" do
        assert User.find(2).rss_token
      end

      should_set_the_flash_to /reset/
      should_redirect_to('my account') {'/my/account' }
    end

    context "with no rss_token" do
      setup do
        assert_nil User.find(2).rss_token
        post :reset_rss_key
      end

      should "create a new token" do
        assert User.find(2).rss_token
      end

      should_set_the_flash_to /reset/
      should_redirect_to('my account') {'/my/account' }
    end
  end

  context "POST to reset_api_key" do
    context "with an existing api_token" do
      setup do
        @previous_token_value = User.find(2).api_key # Will generate one if it's missing
        post :reset_api_key
      end

      should "destroy the existing token" do
        assert_not_equal @previous_token_value, User.find(2).api_key
      end

      should "create a new token" do
        assert User.find(2).api_token
      end

      should_set_the_flash_to /reset/
      should_redirect_to('my account') {'/my/account' }
    end

    context "with no api_token" do
      setup do
        assert_nil User.find(2).api_token
        post :reset_api_key
      end

      should "create a new token" do
        assert User.find(2).api_token
      end

      should_set_the_flash_to /reset/
      should_redirect_to('my account') {'/my/account' }
    end
  end
end
