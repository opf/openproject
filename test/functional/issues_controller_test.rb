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
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments
  
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
    assert_not_nil assigns(:changes)
    assert_equal 'application/atom+xml', @response.content_type
  end
  
  def test_show
    get :show, :id => 1
    assert_response :success
    assert_template 'show.rhtml'
    assert_not_nil assigns(:issue)
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
  end

  def test_post_edit
    @request.session[:user_id] = 2
    post :edit, :id => 1, :issue => {:subject => 'Modified subject'}
    assert_redirected_to 'issues/show/1'
    assert_equal 'Modified subject', Issue.find(1).subject
  end
  
  def test_post_change_status
    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    post :change_status, :id => 1,
                         :new_status_id => 2,
                         :issue => { :assigned_to_id => 3 },
                         :notes => 'Assigned to dlopper',
                         :confirm => 1
    assert_redirected_to 'issues/show/1'
    issue.reload
    assert_equal 2, issue.status_id
    j = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size
  end
  
  def test_context_menu
    @request.session[:user_id] = 2
    get :context_menu, :id => 1
    assert_response :success
    assert_template 'context_menu'
  end
  
  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1
    assert_redirected_to 'projects/1/issues'
    assert_nil Issue.find_by_id(1)
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
