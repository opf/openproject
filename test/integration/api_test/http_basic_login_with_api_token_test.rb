require "#{File.dirname(__FILE__)}/../../test_helper"

class ApiTest::HttpBasicLoginWithApiTokenTest < ActionController::IntegrationTest
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
      context "with a valid HTTP authentication using the API token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'X')
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
          @token = Token.generate!(:user => @user, :action => 'feeds')
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
      context "with a valid HTTP authentication" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          @authorization = ActionController::HttpAuthentication::Basic.encode_credentials(@token.value, 'DoesNotMatter')
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
          @token = Token.generate!(:user => @user, :action => 'feeds')
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
