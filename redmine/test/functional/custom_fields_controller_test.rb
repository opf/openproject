require File.dirname(__FILE__) + '/../test_helper'
require 'custom_fields_controller'

# Re-raise errors caught by the controller.
class CustomFieldsController; def rescue_action(e) raise e end; end

class CustomFieldsControllerTest < Test::Unit::TestCase
  fixtures :custom_fields

  def setup
    @controller = CustomFieldsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:custom_fields)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:custom_field)
    assert assigns(:custom_field).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:custom_field)
  end

  def test_create
    num_custom_fields = CustomField.count

    post :create, :custom_field => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_custom_fields + 1, CustomField.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:custom_field)
    assert assigns(:custom_field).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil CustomField.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      CustomField.find(1)
    }
  end
end
