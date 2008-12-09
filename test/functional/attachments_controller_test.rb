# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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
require 'attachments_controller'

# Re-raise errors caught by the controller.
class AttachmentsController; def rescue_action(e) raise e end; end


class AttachmentsControllerTest < Test::Unit::TestCase
  fixtures :users, :projects, :roles, :members, :enabled_modules, :issues, :attachments
  
  def setup
    @controller = AttachmentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Attachment.storage_path = "#{RAILS_ROOT}/test/fixtures/files"
    User.current = nil
  end
  
  def test_routing
    assert_routing('/attachments/1', :controller => 'attachments', :action => 'show', :id => '1')
    assert_routing('/attachments/1/filename.ext', :controller => 'attachments', :action => 'show', :id => '1', :filename => 'filename.ext')
    assert_routing('/attachments/download/1', :controller => 'attachments', :action => 'download', :id => '1')
    assert_routing('/attachments/download/1/filename.ext', :controller => 'attachments', :action => 'download', :id => '1', :filename => 'filename.ext')
  end
  
  def test_recognizes
    assert_recognizes({:controller => 'attachments', :action => 'show', :id => '1'}, '/attachments/1')
    assert_recognizes({:controller => 'attachments', :action => 'show', :id => '1'}, '/attachments/show/1')
    assert_recognizes({:controller => 'attachments', :action => 'show', :id => '1', :filename => 'filename.ext'}, '/attachments/1/filename.ext')
    assert_recognizes({:controller => 'attachments', :action => 'download', :id => '1'}, '/attachments/download/1')
    assert_recognizes({:controller => 'attachments', :action => 'download', :id => '1', :filename => 'filename.ext'},'/attachments/download/1/filename.ext')
  end
  
  def test_show_diff
    get :show, :id => 5
    assert_response :success
    assert_template 'diff'
  end
  
  def test_show_text_file
    get :show, :id => 4
    assert_response :success
    assert_template 'file'
  end
  
  def test_show_other
    get :show, :id => 6
    assert_response :success
    assert_equal 'application/octet-stream', @response.content_type
  end
  
  def test_download_text_file
    get :download, :id => 4
    assert_response :success
    assert_equal 'application/x-ruby', @response.content_type
  end
  
  def test_anonymous_on_private_private
    get :download, :id => 7
    assert_redirected_to 'account/login'
  end
  
  def test_destroy_issue_attachment
    issue = Issue.find(3)
    @request.session[:user_id] = 2
    
    assert_difference 'issue.attachments.count', -1 do
      post :destroy, :id => 1
    end
    # no referrer
    assert_redirected_to 'projects/show/ecookbook'
    assert_nil Attachment.find_by_id(1)
    j = issue.journals.find(:first, :order => 'created_on DESC')
    assert_equal 'attachment', j.details.first.property
    assert_equal '1', j.details.first.prop_key
    assert_equal 'error281.txt', j.details.first.old_value
  end
  
  def test_destroy_wiki_page_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 3
      assert_response 302
    end
  end
  
  def test_destroy_project_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 8
      assert_response 302
    end
  end
  
  def test_destroy_version_attachment
    @request.session[:user_id] = 2
    assert_difference 'Attachment.count', -1 do
      post :destroy, :id => 9
      assert_response 302
    end
  end
  
  def test_destroy_without_permission
    post :destroy, :id => 3
    assert_redirected_to '/login'
    assert Attachment.find_by_id(3)
  end
end
