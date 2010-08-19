require "#{File.dirname(__FILE__)}/../test_helper"

class LayoutTest < ActionController::IntegrationTest
  fixtures :all

  test "browsing to a missing page should render the base layout" do
    get "/users/100000000"

    assert_response :not_found

    # UsersController uses the admin layout by default
    assert_select "#admin-menu", :count => 0
  end

  test "browsing to an unauthorized page should render the base layout" do
    user = User.find(9)
    user.password, user.password_confirmation = 'test', 'test'
    user.save!
    
    log_user('miscuser9','test')

    get "/admin"
    assert_response :forbidden
    assert_select "#admin-menu", :count => 0
  end
end
