require "#{File.dirname(__FILE__)}/../../test_helper"

class ApiTest::HttpBasicLoginTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
    Setting.login_required = '1'
  end

  def teardown
    Setting.rest_api_enabled = '0'
    Setting.login_required = '0'
  end
  
  # Using the NewsController because it's a simple API.
  context "get /news" do

    context "in :xml format" do
      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'my_password', :password_confirmation => 'my_password')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'my_password')
          get "/news.xml", nil, :authorization => @authorization
        end
        
        should_respond_with :success
        should_respond_with_content_type :xml
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'wrong_password')
          get "/news.xml", nil, :authorization => @authorization
        end
        
        should_respond_with :unauthorized
        should_respond_with_content_type :xml
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end
      
      context "without credentials" do
        setup do
          get "/projects/onlinestore/news.xml"
        end

        should_respond_with :unauthorized
        should_respond_with_content_type :xml
        should "include_www_authenticate_header" do
          assert @controller.response.headers.has_key?('WWW-Authenticate')
        end
      end
    end

    context "in :json format" do
      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!(:password => 'my_password', :password_confirmation => 'my_password')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'my_password')
          get "/news.json", nil, :authorization => @authorization
        end
        
        should_respond_with :success
        should_respond_with_content_type :json
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, 'wrong_password')
          get "/news.json", nil, :authorization => @authorization
        end
        
        should_respond_with :unauthorized
        should_respond_with_content_type :json
        should "not login as the user" do
          assert_equal User.anonymous, User.current
        end
      end
    end
    
    context "without credentials" do
      setup do
        get "/projects/onlinestore/news.json"
      end

      should_respond_with :unauthorized
      should_respond_with_content_type :json
      should "include_www_authenticate_header" do
        assert @controller.response.headers.has_key?('WWW-Authenticate')
      end
    end
  end
end
