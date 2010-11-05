require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < ActionController::TestCase
  fixtures :projects, :enabled_modules, :roles, :users, :members, :member_roles,
           :issues, :trackers, :issue_statuses,
           :custom_fields, :custom_values,
           :repositories, :changesets
  
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
  
  def test_search_all_projects
    get :index, :q => 'recipe subproject commit', :submit => 'Search'
    assert_response :success
    assert_template 'index'
    
    assert assigns(:results).include?(Issue.find(2))
    assert assigns(:results).include?(Issue.find(5))
    assert assigns(:results).include?(Changeset.find(101))
    assert_tag :dt, :attributes => { :class => /issue/ },
                    :child => { :tag => 'a',  :content => /Add ingredients categories/ },
                    :sibling => { :tag => 'dd', :content => /A comment with inline image: !picture.jpg!/ }
    
    assert assigns(:results_by_type).is_a?(Hash)
    assert_equal 5, assigns(:results_by_type)['changesets']
    assert_tag :a, :content => 'Changesets (5)'
  end
  
  def test_search_issues
    get :index, :q => 'issue', :issues => 1
    assert_response :success
    assert_template 'index'
    
    assert assigns(:results).include?(Issue.find(8))
    assert assigns(:results).include?(Issue.find(5))
    assert_tag :dt, :attributes => { :class => /issue closed/ },
                    :child => { :tag => 'a',  :content => /Closed/ }
  end
  
  def test_search_project_and_subprojects
    get :index, :id => 1, :q => 'recipe subproject', :scope => 'subprojects', :submit => 'Search'
    assert_response :success
    assert_template 'index'
    assert assigns(:results).include?(Issue.find(1))
    assert assigns(:results).include?(Issue.find(5))
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
  
  def test_search_all_words
    # 'all words' is on by default
    get :index, :id => 1, :q => 'recipe updating saving'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 1, results.size
    assert results.include?(Issue.find(3))
  end
  
  def test_search_one_of_the_words
    get :index, :id => 1, :q => 'recipe updating saving', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 3, results.size
    assert results.include?(Issue.find(3))
  end

  def test_search_titles_only_without_result
    get :index, :id => 1, :q => 'recipe updating saving', :all_words => '1', :titles_only => '1', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 0, results.size
  end

  def test_search_titles_only
    get :index, :id => 1, :q => 'recipe', :titles_only => '1', :submit => 'Search'
    results = assigns(:results)
    assert_not_nil results
    assert_equal 2, results.size
  end
  
  def test_search_with_invalid_project_id
    get :index, :id => 195, :q => 'recipe'
    assert_response 404
    assert_nil assigns(:results)
  end

  def test_quick_jump_to_issue
    # issue of a public project
    get :index, :q => "3"
    assert_redirected_to 'issues/3'
    
    # issue of a private project
    get :index, :q => "4"
    assert_response :success
    assert_template 'index'
  end

  def test_large_integer
    get :index, :q => '4615713488'
    assert_response :success
    assert_template 'index'
  end
  
  def test_tokens_with_quotes
    get :index, :id => 1, :q => '"good bye" hello "bye bye"'
    assert_equal ["good bye", "hello", "bye bye"], assigns(:tokens)
  end
end
