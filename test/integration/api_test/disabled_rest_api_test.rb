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

require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::DisabledRestApiTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '0'
    Setting.login_required = '1'
  end

  def teardown
    Setting.rest_api_enabled = '1'
    Setting.login_required = '0'
  end

  # Using the NewsController because it's a simple API.
  context "get /news with the API disabled" do

    context "in :xml format" do
      context "with a valid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          get "/news.xml?key=#{@token.value}"
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :xml
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'my_password', :password_confirmation => 'my_password')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'my_password')
          get "/news.xml", nil, :authorization => @authorization
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :xml
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'X')
          get "/news.xml", nil, :authorization => @authorization
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :xml
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end
    end

    context "in :json format" do
      context "with a valid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          get "/news.json?key=#{@token.value}"
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :json
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'my_password', :password_confirmation => 'my_password')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'my_password')
          get "/news.json", nil, :authorization => @authorization
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :json
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'DoesNotMatter')
          get "/news.json", nil, :authorization => @authorization
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :json
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

    end
  end
end
