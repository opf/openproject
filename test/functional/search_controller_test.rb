require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  fixtures :projects, :issues, :custom_fields, :custom_values
  
  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
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
  
  def test_search_without_searchable_custom_fields
    CustomField.update_all "searchable = #{ActiveRecord::Base.connection.quoted_false}"
    
    get :index, :id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:project)
    
    get :index, :id => 1, :q => "can"
    assert_response :success
    assert_template 'index'
  end
  
  def test_search_with_searchable_custom_fields
    get :index, :id => 1, :q => "stringforcustomfield"
    assert_response :success
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(Issue.find(3))
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
  
  def test_tokens_with_quotes
    get :index, :id => 1, :q => '"good bye" hello "bye bye"'
    assert_equal ["good bye", "hello", "bye bye"], assigns(:tokens)
  end
end
