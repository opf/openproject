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
require 'queries_controller'

# Re-raise errors caught by the controller.
class QueriesController; def rescue_action(e) raise e end; end

class QueriesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :trackers, :issue_statuses, :issue_categories, :enumerations, :issues, :custom_fields, :custom_values, :queries
  
  def setup
    @controller = QueriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_get_new_project_query
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query[is_public]',
                                                 :checked => nil } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => nil,
                                                 :disabled => nil }
  end
  
  def test_get_new_global_query
    @request.session[:user_id] = 2
    get :new
    assert_response :success
    assert_template 'new'
    assert_no_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                    :name => 'query[is_public]' } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => 'checked',
                                                 :disabled => nil }
  end
  
  def test_new_project_public_query
    @request.session[:user_id] = 2
    post :new,
         :project_id => 'ecookbook', 
         :confirm => '1',
         :default_columns => '1',
         :fields => ["status_id", "assigned_to_id"],
         :operators => {"assigned_to_id" => "=", "status_id" => "o"},
         :values => { "assigned_to_id" => ["1"], "status_id" => ["1"]},
         :query => {"name" => "test_new_project_public_query", "is_public" => "1"}
         
    q = Query.find_by_name('test_new_project_public_query')
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook', :query_id => q
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end
  
  def test_new_project_private_query
    @request.session[:user_id] = 3
    post :new,
         :project_id => 'ecookbook', 
         :confirm => '1',
         :default_columns => '1',
         :fields => ["status_id", "assigned_to_id"],
         :operators => {"assigned_to_id" => "=", "status_id" => "o"},
         :values => { "assigned_to_id" => ["1"], "status_id" => ["1"]},
         :query => {"name" => "test_new_project_private_query", "is_public" => "1"}
         
    q = Query.find_by_name('test_new_project_private_query')
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook', :query_id => q
    assert !q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end
  
  def test_new_global_private_query_with_custom_columns
    @request.session[:user_id] = 3
    post :new,
         :confirm => '1',
         :fields => ["status_id", "assigned_to_id"],
         :operators => {"assigned_to_id" => "=", "status_id" => "o"},
         :values => { "assigned_to_id" => ["me"], "status_id" => ["1"]},
         :query => {"name" => "test_new_global_private_query", "is_public" => "1", "column_names" => ["", "tracker", "subject", "priority", "category"]}
         
    q = Query.find_by_name('test_new_global_private_query')
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => nil, :query_id => q
    assert !q.is_public?
    assert !q.has_default_columns?
    assert_equal [:tracker, :subject, :priority, :category], q.columns.collect {|c| c.name}
    assert q.valid?
  end
  
  def test_new_with_sort
    @request.session[:user_id] = 1
    post :new,
         :confirm => '1',
         :default_columns => '1',
         :operators => {"status_id" => "o"},
         :values => {"status_id" => ["1"]},
         :query => {:name => "test_new_with_sort",
                    :is_public => "1", 
                    :sort_criteria => {"0" => ["due_date", "desc"], "1" => ["tracker", ""]}}
    
    query = Query.find_by_name("test_new_with_sort")
    assert_not_nil query
    assert_equal [['due_date', 'desc'], ['tracker', 'asc']], query.sort_criteria
  end
  
  def test_get_edit_global_public_query
    @request.session[:user_id] = 1
    get :edit, :id => 4
    assert_response :success
    assert_template 'edit'
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query[is_public]',
                                                 :checked => 'checked' } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => 'checked',
                                                 :disabled => 'disabled' }
  end

  def test_edit_global_public_query
    @request.session[:user_id] = 1
    post :edit,
         :id => 4, 
         :confirm => '1',
         :default_columns => '1',
         :fields => ["status_id", "assigned_to_id"],
         :operators => {"assigned_to_id" => "=", "status_id" => "o"},
         :values => { "assigned_to_id" => ["1"], "status_id" => ["1"]},
         :query => {"name" => "test_edit_global_public_query", "is_public" => "1"}
         
    assert_redirected_to :controller => 'issues', :action => 'index', :query_id => 4
    q = Query.find_by_name('test_edit_global_public_query')
    assert q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end
  
  def test_get_edit_global_private_query
    @request.session[:user_id] = 3
    get :edit, :id => 3
    assert_response :success
    assert_template 'edit'
    assert_no_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                    :name => 'query[is_public]' } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => 'checked',
                                                 :disabled => 'disabled' }
  end
  
  def test_edit_global_private_query
    @request.session[:user_id] = 3
    post :edit,
         :id => 3, 
         :confirm => '1',
         :default_columns => '1',
         :fields => ["status_id", "assigned_to_id"],
         :operators => {"assigned_to_id" => "=", "status_id" => "o"},
         :values => { "assigned_to_id" => ["me"], "status_id" => ["1"]},
         :query => {"name" => "test_edit_global_private_query", "is_public" => "1"}
         
    assert_redirected_to :controller => 'issues', :action => 'index', :query_id => 3
    q = Query.find_by_name('test_edit_global_private_query')
    assert !q.is_public?
    assert q.has_default_columns?
    assert q.valid?
  end
  
  def test_get_edit_project_private_query
    @request.session[:user_id] = 3
    get :edit, :id => 2
    assert_response :success
    assert_template 'edit'
    assert_no_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                    :name => 'query[is_public]' } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => nil,
                                                 :disabled => nil }
  end
  
  def test_get_edit_project_public_query
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query[is_public]',
                                                 :checked => 'checked'
                                                  } 
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'query_is_for_all',
                                                 :checked => nil,
                                                 :disabled => 'disabled' }
  end
  
  def test_get_edit_sort_criteria
    @request.session[:user_id] = 1
    get :edit, :id => 5
    assert_response :success
    assert_template 'edit'
    assert_tag :tag => 'select', :attributes => { :name => 'query[sort_criteria][0][]' },
                                 :child => { :tag => 'option', :attributes => { :value => 'priority',
                                                                                :selected => 'selected' } }
    assert_tag :tag => 'select', :attributes => { :name => 'query[sort_criteria][0][]' },
                                 :child => { :tag => 'option', :attributes => { :value => 'desc',
                                                                                :selected => 'selected' } }
  end
  
  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook', :set_filter => 1, :query_id => nil
    assert_nil Query.find_by_id(1)
  end
end
