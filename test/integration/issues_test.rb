require "#{File.dirname(__FILE__)}/../test_helper"

class IssuesTest < ActionController::IntegrationTest
  fixtures :projects, :users, :trackers, :issue_statuses, :issues, :permissions, :permissions_roles, :enumerations

  # create an issue
  def test_add_issue
    log_user('jsmith', 'jsmith')
    get "projects/add_issue/1", :tracker_id => "1"
    assert_response :success
    assert_template "projects/add_issue"
    
    post "projects/add_issue/1", :tracker_id => "1",
                                 :issue => { :start_date => "2006-12-26", 
                                             :priority_id => "3", 
                                             :subject => "new test issue", 
                                             :category_id => "", 
                                             :description => "new issue", 
                                             :done_ratio => "0",
                                             :due_date => "",
                                             :assigned_to_id => "" }
    # find created issue
    issue = Issue.find_by_subject("new test issue")
    assert_kind_of Issue, issue

    # check redirection
    assert_redirected_to "projects/list_issues/1"
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
 
    file_data_1 = "some text...."
    file_name_1 = "sometext.txt"
    file_data_2 = "more text..."
    file_name_2 = "moretext.txt"
    
    boundary = "rubyqMY6QN9bp6e4kS21H4y0zxcvoor"
    headers = { "Content-Type" => "multipart/form-data; boundary=#{boundary}" }

    data = [
            "--" + boundary,
            "Content-Disposition: form-data; name=\"attachments[]\"; filename=\"#{file_name_1}\"",
            "Content-Type: text/plain",
            "", file_data_1, 
            "--" + boundary,
            "Content-Disposition: form-data; name=\"attachments[]\"; filename=\"#{file_name_2}\"",
            "Content-Type: text/plain",
            "", file_data_2, 
            "--" + boundary, ""
            ].join("\x0D\x0A")
     
    post "issues/add_attachment/1", data, headers
    assert_redirected_to "issues/show/1"
    
    # make sure attachment was saved
    attachment = Issue.find(1).attachments.find_by_filename(file_name_1)
    assert_kind_of Attachment, attachment
    assert_equal Issue.find(1), attachment.container
    # verify the size of the attachment stored in db
    assert_equal file_data_1.length, attachment.filesize
    # verify that the attachment was written to disk
    assert File.exist?(attachment.diskfile)
    
    # remove the attachments
    Issue.find(1).attachments.each(&:destroy)
    assert_equal 0, Issue.find(1).attachments.length
  end

end
