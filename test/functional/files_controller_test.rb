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

  def test_create_file
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    Setting.notified_events = ['file_added']
    ActionMailer::Base.deliveries.clear
    
    assert_difference 'Attachment.count' do
      post :create, :id => 1, :version_id => '',
           :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
      assert_response :redirect
    end
    assert_redirected_to 'projects/ecookbook/files'
    a = Attachment.find(:first, :order => 'created_on DESC')
    assert_equal 'testfile.txt', a.filename
    assert_equal Project.find(1), a.container

    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert_equal "[eCookbook] New file", mail.subject
    assert mail.body.include?('testfile.txt')
  end
  
  def test_create_version_file
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    Setting.notified_events = ['file_added']
    
    assert_difference 'Attachment.count' do
      post :create, :id => 1, :version_id => '2',
           :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
      assert_response :redirect
    end
    assert_redirected_to 'projects/ecookbook/files'
    a = Attachment.find(:first, :order => 'created_on DESC')
    assert_equal 'testfile.txt', a.filename
    assert_equal Version.find(2), a.container
  end
  
end
