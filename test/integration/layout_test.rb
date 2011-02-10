require File.expand_path('../../test_helper', __FILE__)

class LayoutTest < ActionController::IntegrationTest
  fixtures :all

  test "browsing to a missing page should render the base layout" do
    get "/users/100000000"

    assert_response :not_found

    # UsersController uses the admin layout by default
    assert_select "#admin-menu", :count => 0
  end

  test "browsing to an unauthorized page should render the base layout" do
    change_user_password('miscuser9', 'test')
    
    log_user('miscuser9','test')

    get "/admin"
    assert_response :forbidden
    assert_select "#admin-menu", :count => 0
  end
end
