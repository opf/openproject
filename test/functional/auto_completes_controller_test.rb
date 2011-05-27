require File.expand_path('../../test_helper', __FILE__)

class AutoCompletesControllerTest < ActionController::TestCase
  fixtures :all

  def test_issues_should_not_be_case_sensitive
    get :issues, :project_id => 'ecookbook', :q => 'ReCiPe'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).detect {|issue| issue.subject.match /recipe/}
  end
  
  def test_issues_should_return_issue_with_given_id
    get :issues, :project_id => 'subproject1', :q => '13'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(Issue.find(13))
  end

  test 'should return issues matching a given id' do
    @project = Project.find('subproject1')
    @issue_21 = Issue.generate_for_project!(@project, :id => 21)
    @issue_2101 = Issue.generate_for_project!(@project, :id => 2101)
    @issue_2102 = Issue.generate_for_project!(@project, :id => 2102)
    @issue_with_subject = Issue.generate_for_project!(@project, :subject => 'This has 21 in the subject')

    get :issues, :project_id => @project.id, :q => '21'

    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(@issue_21)
    assert assigns(:issues).include?(@issue_2101)
    assert assigns(:issues).include?(@issue_2102)
    assert assigns(:issues).include?(@issue_with_subject)
    assert_equal assigns(:issues).size, assigns(:issues).uniq.size, "Issues list includes duplicates"
  end
  
  def test_auto_complete_with_scope_all_and_cross_project_relations
    Setting.cross_project_issue_relations = '1'
    get :issues, :project_id => 'ecookbook', :q => '13', :scope => 'all'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(Issue.find(13))
  end
     
  def test_auto_complete_with_scope_all_without_cross_project_relations
    Setting.cross_project_issue_relations = '0'
    get :issues, :project_id => 'ecookbook', :q => '13', :scope => 'all'
    assert_response :success
    assert_equal [], assigns(:issues)
  end
end
