# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTest < Test::Unit::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :issues,
           :issue_statuses,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_trackers,
           :time_entries
  
  def setup
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
  end

  def test_index_with_project
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
  end
  
  def test_index_with_project_and_filter
    get :index, :project_id => 1, :set_filter => 1
    assert_response :success
    assert_template 'index.rhtml'
    assert_not_nil assigns(:issues)
  end
  
  def test_index_csv_with_project
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type

    get :index, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv', @response.content_type
  end
  
  def test_index_pdf
    get :index, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
    
    get :index, :project_id => 1, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'application/pdf', @response.content_type
  end
  
  def test_changes
    get :changes, :project_id => 1
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end
  
  def test_show_by_anonymous
    get :show, :id => 1
    assert_response :success
    assert_template 'show.rhtml'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
    
    # anonymous role is allowed to add a note
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end
  
  def test_show_by_manager
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success
    
    assert_tag :tag => 'form',
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Change properties/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Log time/ } },
               :descendant => { :tag => 'fieldset',
                                :child => { :tag => 'legend', 
                                            :content => /Notes/ } }
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'
    
    assert_tag :tag => 'input', :attributes => { :name => 'custom_fields[2]',
                                                 :value => 'Default string' }
  end

  def test_get_new_without_tracker_id
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    
    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal Project.find(1).trackers.first, issue.tracker
  end
  
  def test_update_new_form
    @request.session[:user_id] = 2
    xhr :post, :new, :project_id => 1,
                     :issue => {:tracker_id => 2, 
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'new'
  end
  
  def test_post_new
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5},
               :custom_fields => {'2' => 'Value for field 2'}
    assert_redirected_to 'issues/show'
    
    issue = Issue.find_by_subject('This is the test_new issue')
    assert_not_nil issue
    assert_equal 2, issue.author_id
    v = issue.custom_values.find_by_custom_field_id(2)
    assert_not_nil v
    assert_equal 'Value for field 2', v.value
  end
  
  def test_post_new_without_custom_fields_param
    @request.session[:user_id] = 2
    post :new, :project_id => 1, 
               :issue => {:tracker_id => 1,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5}
    assert_redirected_to 'issues/show'
  end
  
  def test_copy_issue
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 1
    assert_template 'new'
    assert_not_nil assigns(:issue)
    orig = Issue.find(1)
    assert_equal orig.subject, assigns(:issue).subject
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
  end
  
  def test_get_edit_with_params
    @request.session[:user_id] = 2
    get :edit, :id => 1, :issue => { :status_id => 5, :priority_id => 7 }
    assert_response :success
    assert_template 'edit'
    
    issue = assigns(:issue)
    assert_not_nil issue
    
    assert_equal 5, issue.status_id
    assert_tag :select, :attributes => { :name => 'issue[status_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Closed',
                                    :attributes => { :selected => 'selected' } }
                                    
    assert_equal 7, issue.priority_id
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', 
                                    :content => 'Urgent',
                                    :attributes => { :selected => 'selected' } }
  end

  def test_post_edit
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    
    issue = Issue.find(1)
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'
    
    post :edit, :id => 1, :issue => {:subject => new_subject}
    assert_redirected_to 'issues/show/1'
    issue.reload
    assert_equal new_subject, issue.subject
    
    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert mail.body.include?("Subject changed from #{old_subject} to #{new_subject}")
  end
  
  def test_post_edit_with_status_and_assignee_change
    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    post :edit,
         :id => 1,
         :issue => { :status_id => 2, :assigned_to_id => 3 },
         :notes => 'Assigned to dlopper'
    assert_redirected_to 'issues/show/1'
    issue.reload
    assert_equal 2, issue.status_id
    j = issue.journals.find(:first, :order => 'id DESC')
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?("Status changed from New to Assigned")
  end
  
  def test_post_edit_with_note_only
    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'
    # anonymous user
    post :edit,
         :id => 1,
         :notes => notes
    assert_redirected_to 'issues/show/1'
    j = Issue.find(1).journals.find(:first, :order => 'id DESC')
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?(notes)
  end
  
  def test_post_edit_with_note_and_spent_time
    @request.session[:user_id] = 2
    spent_hours_before = Issue.find(1).spent_hours
    post :edit,
         :id => 1,
         :notes => '2.5 hours added',
         :time_entry => { :hours => '2.5', :comments => '', :activity_id => Enumeration.get_values('ACTI').first }
    assert_redirected_to 'issues/show/1'
    
    issue = Issue.find(1)
    
    j = issue.journals.find(:first, :order => 'id DESC')
    assert_equal '2.5 hours added', j.notes
    assert_equal 0, j.details.size
    
    t = issue.time_entries.find(:first, :order => 'id DESC')
    assert_not_nil t
    assert_equal 2.5, t.hours
    assert_equal spent_hours_before + 2.5, issue.spent_hours
  end
  
  def test_post_edit_with_attachment_only
    # anonymous user
    post :edit,
         :id => 1,
         :notes => '',
         :attachments => {'1' => {'file' => test_uploaded_file('testfile.txt', 'text/plain')}}
    assert_redirected_to 'issues/show/1'
    j = Issue.find(1).journals.find(:first, :order => 'id DESC')
    assert j.notes.blank?
    assert_equal 1, j.details.size
    assert_equal 'testfile.txt', j.details.first.value
    assert_equal User.anonymous, j.user
    
    mail = ActionMailer::Base.deliveries.last
    assert mail.body.include?('testfile.txt')
  end
  
  def test_post_edit_with_no_change
    issue = Issue.find(1)
    issue.journals.clear
    ActionMailer::Base.deliveries.clear
    
    post :edit,
         :id => 1,
         :notes => ''
    assert_redirected_to 'issues/show/1'
    
    issue.reload
    assert issue.journals.empty?
    # No email should be sent
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_bulk_edit
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit, :ids => [1, 2], :priority_id => 7, :notes => 'Bulk editing', :assigned_to_id => ''
    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.find_all_by_id([1, 2]).collect {|i| i.priority.id}
    assert_equal 'Bulk editing', Issue.find(1).journals.find(:first, :order => 'created_on DESC').notes
  end

  def test_bulk_unassign
    assert_not_nil Issue.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
    post :bulk_edit, :ids => [1, 2], :notes => 'Bulk unassigning', :assigned_to_id => 'none'
    assert_response 302
    # check that the issues were updated
    assert_nil Issue.find(2).assigned_to
  end
  
  def test_move_one_issue_to_another_project
    @request.session[:user_id] = 1
    post :move, :id => 1, :new_project_id => 2
    assert_redirected_to 'projects/ecookbook/issues'
    assert_equal 2, Issue.find(1).project_id
  end

  def test_bulk_move_to_another_project
    @request.session[:user_id] = 1
    post :move, :ids => [1, 2], :new_project_id => 2
    assert_redirected_to 'projects/ecookbook/issues'
    # Issues moved to project 2
    assert_equal 2, Issue.find(1).project_id
    assert_equal 2, Issue.find(2).project_id
    # No tracker change
    assert_equal 1, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end
 
  def test_bulk_move_to_another_tracker
    @request.session[:user_id] = 1
    post :move, :ids => [1, 2], :new_tracker_id => 2
    assert_redirected_to 'projects/ecookbook/issues'
    assert_equal 2, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end
  
  def test_context_menu_one_issue
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/edit/1',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => '/issues/edit/1?issue%5Bstatus_id%5D=5',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/edit/1?issue%5Bpriority_id%5D=8',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/edit/1?issue%5Bassigned_to_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/projects/ecookbook/issues/new?copy_from=1',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1',
                                             :class => 'icon-del' }
  end

  def test_context_menu_one_issue_by_anonymous
    get :context_menu, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_context_menu_multiple_issues_of_same_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1&amp;ids%5B%5D=2',
                                             :class => 'icon-del' }
  end

  def test_context_menu_multiple_issues_of_different_project
    @request.session[:user_id] = 2
    get :context_menu, :ids => [1, 2, 4]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end
  
  def test_destroy_issue_with_no_time_entries
    @request.session[:user_id] = 2
    post :destroy, :id => 3
    assert_redirected_to 'projects/ecookbook/issues'
    assert_nil Issue.find_by_id(3)
  end

  def test_destroy_issues_with_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3]
    assert_response :success
    assert_template 'destroy'
    assert_not_nil assigns(:hours)
    assert Issue.find_by_id(1) && Issue.find_by_id(3)
  end

  def test_destroy_issues_and_destroy_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'destroy'
    assert_redirected_to 'projects/ecookbook/issues'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find_by_id([1, 2])
  end

  def test_destroy_issues_and_assign_time_entries_to_project
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'nullify'
    assert_redirected_to 'projects/ecookbook/issues'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find(1).issue_id
    assert_nil TimeEntry.find(2).issue_id
  end
  
  def test_destroy_issues_and_reassign_time_entries_to_another_issue
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'reassign', :reassign_to_id => 2
    assert_redirected_to 'projects/ecookbook/issues'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_equal 2, TimeEntry.find(1).issue_id
    assert_equal 2, TimeEntry.find(2).issue_id
  end
  
  def test_destroy_attachment
    issue = Issue.find(3)
    a = issue.attachments.size
    @request.session[:user_id] = 2
    post :destroy_attachment, :id => 3, :attachment_id => 1
    assert_redirected_to 'issues/show/3'
    assert_nil Attachment.find_by_id(1)
    issue.reload
    assert_equal((a-1), issue.attachments.size)
    j = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal 'attachment', j.details.first.property
  end
end
