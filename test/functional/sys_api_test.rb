require File.dirname(__FILE__) + '/../test_helper'
require 'sys_controller'

# Re-raise errors caught by the controller.
class SysController; def rescue_action(e) raise e end; end

class SysControllerTest < Test::Unit::TestCase
  fixtures :projects, :enabled_modules, :repositories
  
  def setup
    @controller = SysController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    # Enable WS
    Setting.sys_api_enabled = 1
  end
  
  def test_projects_with_repository_enabled
    result = invoke :projects_with_repository_enabled
    assert_equal EnabledModule.count(:all, :conditions => {:name => 'repository'}), result.size
    
    project = result.first
    assert project.is_a?(AWSProjectWithRepository)
    
    assert project.respond_to?(:id)
    assert_equal 1, project.id
    
    assert project.respond_to?(:identifier)
    assert_equal 'ecookbook', project.identifier
    
    assert project.respond_to?(:name)
    assert_equal 'eCookbook', project.name
    
    assert project.respond_to?(:is_public)
    assert project.is_public
    
    assert project.respond_to?(:repository)
    assert project.repository.is_a?(Repository)
  end

  def test_repository_created
    project = Project.find(3)
    assert_nil project.repository
    assert invoke(:repository_created, project.identifier, 'Subversion', 'http://localhost/svn')
    project.reload
    assert_not_nil project.repository
    assert project.repository.is_a?(Repository::Subversion)
    assert_equal 'http://localhost/svn', project.repository.url
  end
end
