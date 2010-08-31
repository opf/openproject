require File.dirname(__FILE__) + '/../test_helper'

class FilesControllerTest < ActionController::TestCase
  fixtures :all
  
  def setup
    @controller = FilesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end

  def test_index
    get :index, :id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:containers)
    
    # file attached to the project
    assert_tag :a, :content => 'project_file.zip',
                   :attributes => { :href => '/attachments/download/8/project_file.zip' }
    
    # file attached to a project's version
    assert_tag :a, :content => 'version_file.zip',
                   :attributes => { :href => '/attachments/download/9/version_file.zip' }
  end

end
