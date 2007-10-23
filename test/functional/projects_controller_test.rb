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
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :enabled_modules, :enumerations

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:project_tree)
  end
  
  def test_show
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:project)
  end
  
  def test_list_documents
    get :list_documents, :id => 1
    assert_response :success
    assert_template 'list_documents'
    assert_not_nil assigns(:documents)
  end
  
  def test_list_issues
    get :list_issues, :id => 1
    assert_response :success
    assert_template 'list_issues'
    assert_not_nil assigns(:issues)
  end
  
  def test_list_issues_with_filter
    get :list_issues, :id => 1, :set_filter => 1
    assert_response :success
    assert_template 'list_issues'
    assert_not_nil assigns(:issues)
  end
  
  def test_list_issues_reset_filter
    post :list_issues, :id => 1
    assert_response :success
    assert_template 'list_issues'
    assert_not_nil assigns(:issues)
  end
  
  def test_export_issues_csv
    get :export_issues_csv, :id => 1
    assert_response :success
    assert_not_nil assigns(:issues)
  end
  
  def test_bulk_edit_issues
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_edit_issues, :id => 1, :issue_ids => [1, 2], :priority_id => 7, :notes => 'Bulk editing', :assigned_to_id => ''
    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.find_all_by_id([1, 2]).collect {|i| i.priority.id}
    assert_equal 'Bulk editing', Issue.find(1).journals.find(:first, :order => 'created_on DESC').notes
  end

  def test_list_news
    get :list_news, :id => 1
    assert_response :success
    assert_template 'list_news'
    assert_not_nil assigns(:newss)
  end

  def test_list_files
    get :list_files, :id => 1
    assert_response :success
    assert_template 'list_files'
    assert_not_nil assigns(:versions)
  end

  def test_changelog
    get :changelog, :id => 1
    assert_response :success
    assert_template 'changelog'
    assert_not_nil assigns(:versions)
  end
  
  def test_roadmap
    get :roadmap, :id => 1
    assert_response :success
    assert_template 'roadmap'
    assert_not_nil assigns(:versions)
  end

  def test_activity
    get :activity, :id => 1
    assert_response :success
    assert_template 'activity'
    assert_not_nil assigns(:events_by_day)
  end
  
  def test_archive    
    @request.session[:user_id] = 1 # admin
    post :archive, :id => 1
    assert_redirected_to 'admin/projects'
    assert !Project.find(1).active?
  end
  
  def test_unarchive
    @request.session[:user_id] = 1 # admin
    Project.find(1).archive
    post :unarchive, :id => 1
    assert_redirected_to 'admin/projects'
    assert Project.find(1).active?
  end
end
