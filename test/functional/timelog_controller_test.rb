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
  fixtures :projects, :enabled_modules, :roles, :members, :issues, :time_entries, :users, :trackers, :enumerations, :issue_statuses, :custom_fields, :custom_values

  def setup
    @controller = TimelogController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_edit_routing
    assert_routing(
      {:method => :get, :path => '/issues/567/time_entries/new'},
      :controller => 'timelog', :action => 'edit', :issue_id => '567'
    )
    assert_routing(
      {:method => :get, :path => '/projects/ecookbook/time_entries/new'},
      :controller => 'timelog', :action => 'edit', :project_id => 'ecookbook'
    )
    assert_routing(
      {:method => :get, :path => '/projects/ecookbook/issues/567/time_entries/new'},
      :controller => 'timelog', :action => 'edit', :project_id => 'ecookbook', :issue_id => '567'
    )

    #TODO: change new form to POST to issue_time_entries_path instead of to edit action
    #TODO: change edit form to PUT to time_entry_path
    assert_routing(
      {:method => :get, :path => '/time_entries/22/edit'},
      :controller => 'timelog', :action => 'edit', :id => '22'
    )
  end
  
  def test_get_edit
    @request.session[:user_id] = 3
    get :edit, :project_id => 1
    assert_response :success
    assert_template 'edit'
    # Default activity selected
    assert_tag :tag => 'option', :attributes => { :selected => 'selected' },
                                 :content => 'Development'
  end
  
  def test_get_edit_existing_time
    @request.session[:user_id] = 2
    get :edit, :id => 2, :project_id => nil
    assert_response :success
    assert_template 'edit'
    # Default activity selected
    assert_tag :tag => 'form', :attributes => { :action => '/projects/ecookbook/timelog/edit/2' }
  end
  
  def test_post_edit
    # TODO: should POST to issues’ time log instead of project. change form
    # and routing
    @request.session[:user_id] = 3
    post :edit, :project_id => 1,
                :time_entry => {:comments => 'Some work on TimelogControllerTest',
                                # Not the default activity
                                :activity_id => '11',
                                :spent_on => '2008-03-14',
                                :issue_id => '1',
                                :hours => '7.3'}
    assert_redirected_to :action => 'details', :project_id => 'ecookbook'
    
    i = Issue.find(1)
    t = TimeEntry.find_by_comments('Some work on TimelogControllerTest')
    assert_not_nil t
    assert_equal 11, t.activity_id
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
    assert_redirected_to :action => 'details', :project_id => 'ecookbook'
    entry.reload
    
    assert_equal 8, entry.hours
    assert_equal 2, entry.issue_id
    assert_equal 2, entry.user_id
  end
  
  def test_destroy_routing
    #TODO: use DELETE to time_entry_path
    assert_routing(
      {:method => :post, :path => '/time_entries/55/destroy'},
      :controller => 'timelog', :action => 'destroy', :id => '55'
    )
  end
  
  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 1
    assert_redirected_to :action => 'details', :project_id => 'ecookbook'
    assert_nil TimeEntry.find_by_id(1)
  end
  
  def test_report_routing
    assert_routing(
      {:method => :get, :path => '/projects/567/time_entries/report'},
      :controller => 'timelog', :action => 'report', :project_id => '567'
    )
    assert_routing(
      {:method => :get, :path => '/projects/567/time_entries/report.csv'},
      :controller => 'timelog', :action => 'report', :project_id => '567', :format => 'csv'
    )
  end
  
  def test_report_no_criteria
    get :report, :project_id => 1
    assert_response :success
    assert_template 'report'
  end
  
  def test_report_routing_for_all_projects
    assert_routing(
      {:method => :get, :path => '/time_entries/report'},
      :controller => 'timelog', :action => 'report'
    )
  end

  def test_report_all_projects
    get :report
    assert_response :success
    assert_template 'report'
  end
  
  def test_report_all_projects_denied
    r = Role.anonymous
    r.permissions.delete(:view_time_entries)
    r.permissions_will_change!
    r.save
    get :report
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Ftime_entries%2Freport'
  end
  
  def test_report_all_projects_one_criteria
    get :report, :columns => 'week', :from => "2007-04-01", :to => "2007-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "8.65", "%.2f" % assigns(:total_hours)
  end

  def test_report_all_time
    get :report, :project_id => 1, :criterias => ['project', 'issue']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end

  def test_report_all_time_by_day
    get :report, :project_id => 1, :criterias => ['project', 'issue'], :columns => 'day'
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
    assert_tag :tag => 'th', :content => '2007-03-12'
  end
  
  def test_report_one_criteria
    get :report, :project_id => 1, :columns => 'week', :from => "2007-04-01", :to => "2007-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "8.65", "%.2f" % assigns(:total_hours)
  end
  
  def test_report_two_criterias
    get :report, :project_id => 1, :columns => 'month', :from => "2007-01-01", :to => "2007-12-31", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end
  
  def test_report_custom_field_criteria
    get :report, :project_id => 1, :criterias => ['project', 'cf_1']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_not_nil assigns(:criterias)
    assert_equal 2, assigns(:criterias).size
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
    # Custom field column
    assert_tag :tag => 'th', :content => 'Database'
    # Custom field row
    assert_tag :tag => 'td', :content => 'MySQL',
                             :sibling => { :tag => 'td', :attributes => { :class => 'hours' },
                                                         :child => { :tag => 'span', :attributes => { :class => 'hours hours-int' },
                                                                                     :content => '1' }}
  end
  
  def test_report_one_criteria_no_result
    get :report, :project_id => 1, :columns => 'week', :from => "1998-04-01", :to => "1998-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "0.00", "%.2f" % assigns(:total_hours)
  end
  
  def test_report_all_projects_csv_export
    get :report, :columns => 'month', :from => "2007-01-01", :to => "2007-06-30", :criterias => ["project", "member", "activity"], :format => "csv"
    assert_response :success
    assert_equal 'text/csv', @response.content_type
    lines = @response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end
  
  def test_report_csv_export
    get :report, :project_id => 1, :columns => 'month', :from => "2007-01-01", :to => "2007-06-30", :criterias => ["project", "member", "activity"], :format => "csv"
    assert_response :success
    assert_equal 'text/csv', @response.content_type
    lines = @response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end
  
  def test_details_all_projects
    get :details
    assert_response :success
    assert_template 'details'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end
  
  def test_project_details_routing
    assert_routing(
      {:method => :get, :path => '/projects/567/time_entries'},
      :controller => 'timelog', :action => 'details', :project_id => '567'
    )
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
    assert_equal '2007-03-11'.to_date, assigns(:from)
    assert_equal '2007-04-22'.to_date, assigns(:to)
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
  
  def test_issue_details_routing
    assert_routing(
      {:method => :get, :path => 'time_entries'},
      :controller => 'timelog', :action => 'details'
    )
    assert_routing(
      {:method => :get, :path => '/issues/234/time_entries'},
      :controller => 'timelog', :action => 'details', :issue_id => '234'
    )
    # TODO: issue detail page shouldnt link to project_issue_time_entries_path but to normal issues one
    # doesnt seem to have effect on resulting page so controller can be left untouched
    assert_routing(
      {:method => :get, :path => '/projects/ecookbook/issues/123/time_entries'},
      :controller => 'timelog', :action => 'details', :project_id => 'ecookbook', :issue_id => '123'
    )
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
    assert_equal '2007-03-11'.to_date, assigns(:from)
    assert_equal '2007-04-22'.to_date, assigns(:to)
  end
  
  def test_details_formatted_routing
    assert_routing(
      {:method => :get, :path => 'time_entries.atom'},
      :controller => 'timelog', :action => 'details', :format => 'atom'
    )
    assert_routing(
      {:method => :get, :path => 'time_entries.csv'},
      :controller => 'timelog', :action => 'details', :format => 'csv'
    )
  end
  
  def test_details_for_project_formatted_routing
    assert_routing(
      {:method => :get, :path => '/projects/567/time_entries.atom'},
      :controller => 'timelog', :action => 'details', :format => 'atom', :project_id => '567'
    )
    assert_routing(
      {:method => :get, :path => '/projects/567/time_entries.csv'},
      :controller => 'timelog', :action => 'details', :format => 'csv', :project_id => '567'
    )
  end
  
  def test_details_for_issue_formatted_routing
    assert_routing(
      {:method => :get, :path => '/projects/ecookbook/issues/123/time_entries.atom'},
      :controller => 'timelog', :action => 'details', :project_id => 'ecookbook', :issue_id => '123', :format => 'atom'
    )
    assert_routing(
      {:method => :get, :path => '/projects/ecookbook/issues/123/time_entries.csv'},
      :controller => 'timelog', :action => 'details', :project_id => 'ecookbook', :issue_id => '123', :format => 'csv'
    )
  end
  
  def test_details_atom_feed
    get :details, :project_id => 1, :format => 'atom'
    assert_response :success
    assert_equal 'application/atom+xml', @response.content_type
    assert_not_nil assigns(:items)
    assert assigns(:items).first.is_a?(TimeEntry)
  end
  
  def test_details_all_projects_csv_export
    get :details, :format => 'csv'
    assert_response :success
    assert_equal 'text/csv', @response.content_type
    assert @response.body.include?("Date,User,Activity,Project,Issue,Tracker,Subject,Hours,Comment\n")
    assert @response.body.include?("\n04/21/2007,redMine Admin,Design,eCookbook,3,Bug,Error 281 when updating a recipe,1.0,\"\"\n")
  end
  
  def test_details_csv_export
    get :details, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_equal 'text/csv', @response.content_type
    assert @response.body.include?("Date,User,Activity,Project,Issue,Tracker,Subject,Hours,Comment\n")
    assert @response.body.include?("\n04/21/2007,redMine Admin,Design,eCookbook,3,Bug,Error 281 when updating a recipe,1.0,\"\"\n")
  end
end
