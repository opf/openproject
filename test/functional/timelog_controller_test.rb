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
require 'timelog_controller'

# Re-raise errors caught by the controller.
class TimelogController; def rescue_action(e) raise e end; end

class TimelogControllerTest < Test::Unit::TestCase
  fixtures :projects, :roles, :members, :issues, :time_entries, :users, :trackers, :enumerations, :issue_statuses

  def setup
    @controller = TimelogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_create
    @request.session[:user_id] = 3
    post :edit, :project_id => 1,
                :time_entry => {:comments => 'Some work on TimelogControllerTest',
                                :activity_id => '10',
                                :spent_on => '2008-03-14',
                                :issue_id => '1',
                                :hours => '7.3'}
    assert_redirected_to 'projects/ecookbook/timelog/details'
    
    i = Issue.find(1)
    t = TimeEntry.find_by_comments('Some work on TimelogControllerTest')
    assert_not_nil t
    assert_equal 7.3, t.hours
    assert_equal 3, t.user_id
    assert_equal i, t.issue
    assert_equal i.project, t.project
  end
  
  def test_update
    entry = TimeEntry.find(1)
    assert_equal 1, entry.issue_id
    assert_equal 2, entry.user_id
    
    @request.session[:user_id] = 1
    post :edit, :id => 1,
                :time_entry => {:issue_id => '2',
                                :hours => '8'}
    assert_redirected_to 'projects/ecookbook/timelog/details'
    entry.reload
    
    assert_equal 8, entry.hours
    assert_equal 2, entry.issue_id
    assert_equal 2, entry.user_id
  end
  
  def destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1
    assert_redirected_to 'projects/ecookbook/timelog/details'
    assert_nil TimeEntry.find_by_id(1)
  end

  def test_report_no_criteria
    get :report, :project_id => 1
    assert_response :success
    assert_template 'report'
  end
  
  def test_report_one_criteria
    get :report, :project_id => 1, :period => 'week', :date_from => "2007-04-01", :date_to => "2007-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "8.65", "%.2f" % assigns(:total_hours)
 end
  
  def test_report_two_criterias
    get :report, :project_id => 1, :period => 'month', :date_from => "2007-01-01", :date_to => "2007-12-31", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end
  
  def test_report_one_criteria_no_result
    get :report, :project_id => 1, :period => 'week', :date_from => "1998-04-01", :date_to => "1998-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "0.00", "%.2f" % assigns(:total_hours)
 end

  def test_details_at_project_level
    get :details, :project_id => 1
    assert_response :success
    assert_template 'details'
    assert_not_nil assigns(:entries)
    assert_equal 4, assigns(:entries).size
    # project and subproject
    assert_equal [1, 3], assigns(:entries).collect(&:project_id).uniq.sort
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
    # display all time by default
    assert_nil assigns(:from)
    assert_nil assigns(:to)
  end
  
  def test_details_at_project_level_with_date_range
    get :details, :project_id => 1, :from => '2007-03-20', :to => '2007-04-30'
    assert_response :success
    assert_template 'details'
    assert_not_nil assigns(:entries)
    assert_equal 3, assigns(:entries).size
    assert_not_nil assigns(:total_hours)
    assert_equal "12.90", "%.2f" % assigns(:total_hours)
    assert_equal '2007-03-20'.to_date, assigns(:from)
    assert_equal '2007-04-30'.to_date, assigns(:to)
  end

  def test_details_at_project_level_with_period
    get :details, :project_id => 1, :period => '7_days'
    assert_response :success
    assert_template 'details'
    assert_not_nil assigns(:entries)
    assert_not_nil assigns(:total_hours)
    assert_equal Date.today - 7, assigns(:from)
    assert_equal Date.today, assigns(:to)
  end
  
  def test_details_at_issue_level
    get :details, :issue_id => 1
    assert_response :success
    assert_template 'details'
    assert_not_nil assigns(:entries)
    assert_equal 2, assigns(:entries).size
    assert_not_nil assigns(:total_hours)
    assert_equal 154.25, assigns(:total_hours)
    # display all time by default
    assert_nil assigns(:from)
    assert_nil assigns(:to)
  end
end
