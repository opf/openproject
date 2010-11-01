require "#{File.dirname(__FILE__)}/../../test_helper"

class ApiTest::TokenAuthenticationTest < ActionController::IntegrationTest
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
      context "with a valid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'api')
          get "/news.xml?key=#{@token.value}"
        end
        
        should_respond_with :success
        should_respond_with_content_type :xml
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'feeds')
          get "/news.xml?key=#{@token.value}"
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
        
        should_respond_with :success
        should_respond_with_content_type :json
        should "login as the user" do
          assert_equal @user, User.current
        end
      end

      context "with an invalid api token" do
        setup do
          @user = User.generate_with_protected!
          @token = Token.generate!(:user => @user, :action => 'feeds')
          get "/news.json?key=#{@token.value}"
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
