require "#{File.dirname(__FILE__)}/../test_helper"

class IssuesTest < ActionController::IntegrationTest
  fixtures :projects, 
           :users,
           :trackers,
           :projects_trackers,
           :issue_statuses,
           :issues,
           :enumerations,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers

  # create an issue
  def test_add_issue
    log_user('jsmith', 'jsmith')
    get 'projects/1/issues/new', :tracker_id => '1'
    assert_response :success
    assert_template 'issues/new'
    
    post 'projects/1/issues/new', :tracker_id => "1",
                                 :issue => { :start_date => "2006-12-26", 
                                             :priority_id => "3", 
                                             :subject => "new test issue", 
                                             :category_id => "", 
                                             :description => "new issue", 
                                             :done_ratio => "0",
                                             :due_date => "",
                                             :assigned_to_id => "" },
                                 :custom_fields => {'2' => 'Value for field 2'}
    # find created issue
    issue = Issue.find_by_subject("new test issue")
    assert_kind_of Issue, issue

    # check redirection
    assert_redirected_to "projects/ecookbook/issues"
    follow_redirect!
    assert assigns(:issues).include?(issue)

    # check issue attributes    
    assert_equal 'jsmith', issue.author.login
    assert_equal 1, issue.project.id
    assert_equal 1, issue.status.id
  end

  # add then remove 2 attachments to an issue
  def test_issue_attachements
    log_user('jsmith', 'jsmith')

    post 'issues/edit/1',
         :notes => 'Some notes',
         :attachments => ([] << ActionController::TestUploadedFile.new(Test::Unit::TestCase.fixture_path + '/files/testfile.txt', 'text/plain'))
    assert_redirected_to "issues/show/1"
    
    # make sure attachment was saved
    attachment = Issue.find(1).attachments.find_by_filename("testfile.txt")
    assert_kind_of Attachment, attachment
    assert_equal Issue.find(1), attachment.container
    # verify the size of the attachment stored in db
    #assert_equal file_data_1.length, attachment.filesize
    # verify that the attachment was written to disk
    assert File.exist?(attachment.diskfile)
    
    # remove the attachments
    Issue.find(1).attachments.each(&:destroy)
    assert_equal 0, Issue.find(1).attachments.length
  end

end
