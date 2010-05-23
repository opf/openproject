require 'test_helper'

class LdapAuthSourcesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    @request.session[:user_id] = 1
  end

  context "get :new" do
    setup do
      get :new
    end

    should_assign_to :auth_source
    should_respond_with :success
    should_render_template :new

    should "initilize a new AuthSource" do
      assert_equal AuthSourceLdap, assigns(:auth_source).class
      assert assigns(:auth_source).new_record?
    end
  end
end
