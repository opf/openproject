require File.expand_path('../../../test_helper', __FILE__)

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
      should_allow_http_basic_auth_with_key(:get, "/news.xml")
    end

    context "in :json format" do
      should_allow_http_basic_auth_with_key(:get, "/news.json")
    end
  end
end
