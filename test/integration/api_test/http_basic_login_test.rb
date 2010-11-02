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
    setup do
      project = Project.find('onlinestore')
      EnabledModule.create(:project => project, :name => 'news')
    end

    context "in :xml format" do
      should_allow_http_basic_auth_with_username_and_password(:get, "/projects/onlinestore/news.xml")
    end

    context "in :json format" do
      should_allow_http_basic_auth_with_username_and_password(:get, "/projects/onlinestore/news.json")
    end
  end
end
