#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::DisabledRestApiTest < ActionDispatch::IntegrationTest
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
  context "get /api/v1/news with the API disabled" do

    context "in :xml format" do
      context "with a valid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          get "/api/v1/news.xml?key=#{@token.value}"
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/xml"
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'adminADMIN!', :password_confirmation => 'adminADMIN!')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'adminADMIN!')
          get "/api/v1/news.xml", nil, :authorization => @authorization
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/xml"
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'X')
          get "/api/v1/news.xml", nil, :authorization => @authorization
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/xml"
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
          get "/api/v1/news.json?key=#{@token.value}"
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/json"
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'adminADMIN!', :password_confirmation => 'adminADMIN!')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'adminADMIN!')
          get "/api/v1/news.json", nil, :authorization => @authorization
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/json"
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'DoesNotMatter')
          get "/api/v1/news.json", nil, :authorization => @authorization
        end

        should respond_with :unauthorized
        should_respond_with_content_type "application/json"
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end

    end
  end
end
