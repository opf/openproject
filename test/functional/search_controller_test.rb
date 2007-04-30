require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  fixtures :projects, :issues
  
  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_search_for_projects
    get :index
    assert_response :success
    assert_template 'index'

    get :index, :q => "cook"
    assert_response :success
    assert_template 'index'
    assert assigns(:results).include?(Project.find(1))
  end
  
  def test_search_in_project
    get :index, :id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:project)
    
    get :index, :id => 1, :q => "can", :scope => ["issues", "news", "documents"]
    assert_response :success
    assert_template 'index'
  end
  
  def test_quick_jump_to_issue
    # issue of a public project
    get :index, :q => "3"
    assert_redirected_to 'issues/show/3'
    
    # issue of a private project
    get :index, :q => "4"
    assert_response :success
    assert_template 'index'
  end
end
