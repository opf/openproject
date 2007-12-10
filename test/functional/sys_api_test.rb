require File.dirname(__FILE__) + '/../test_helper'
require 'sys_controller'

# Re-raise errors caught by the controller.
class SysController; def rescue_action(e) raise e end; end

class SysControllerTest < Test::Unit::TestCase
  fixtures :projects, :repositories
  
  def setup
    @controller = SysController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    # Enable WS
    Setting.sys_api_enabled = 1
  end
  
  def test_projects
    result = invoke :projects
    assert_equal Project.count, result.size 
    assert result.first.is_a?(Project)
  end

  def test_repository_created
    project = Project.find(3)
    assert_nil project.repository
    assert invoke(:repository_created, project.identifier, 'http://localhost/svn')
    project.reload
    assert_not_nil project.repository
  end
end
