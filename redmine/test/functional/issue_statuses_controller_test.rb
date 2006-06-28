require File.dirname(__FILE__) + '/../test_helper'
require 'issue_statuses_controller'

# Re-raise errors caught by the controller.
class IssueStatusesController; def rescue_action(e) raise e end; end

class IssueStatusesControllerTest < Test::Unit::TestCase
  fixtures :issue_statuses

  def setup
    @controller = IssueStatusesController.new
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

    assert_not_nil assigns(:issue_statuses)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:issue_status)
    assert assigns(:issue_status).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:issue_status)
  end

  def test_create
    num_issue_statuses = IssueStatus.count

    post :create, :issue_status => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_issue_statuses + 1, IssueStatus.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:issue_status)
    assert assigns(:issue_status).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil IssueStatus.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      IssueStatus.find(1)
    }
  end
end
