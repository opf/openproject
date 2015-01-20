#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../test_helper', __FILE__)

class TimeEntries::ReportsControllerTest < ActionController::TestCase
  fixtures :all

  def test_report_at_project_level
    get :show, :project_id => 'ecookbook'
    assert_response :success
    assert_template 'report'
    assert_tag :form,
      :attributes => {:action => "/projects/ecookbook/time_entries/report", :id => 'query_form'}
  end

  def test_report_all_projects
    get :show
    assert_response :success
    assert_template 'report'
    assert_tag :form,
      :attributes => {:action => "/time_entries/report", :id => 'query_form'}
  end

  def test_report_all_projects_denied
    r = Role.anonymous
    r.permissions.delete(:view_time_entries)
    r.permissions_will_change!
    r.save
    get :show
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Ftime_entries%2Freport'
  end

  def test_report_all_projects_one_criteria
    get :show, :columns => 'week', :from => "2007-04-01", :to => "2007-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "8.65", "%.2f" % assigns(:total_hours)
  end

  def test_report_all_time
    get :show, :project_id => 1, :criterias => ['project', 'issue']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end

  def test_report_all_time_by_day
    get :show, :project_id => 1, :criterias => ['project', 'issue'], :columns => 'day'
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
    assert_tag :tag => 'th', :content => '2007-03-12'
  end

  def test_report_one_criteria
    get :show, :project_id => 1, :columns => 'week', :from => "2007-04-01", :to => "2007-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "8.65", "%.2f" % assigns(:total_hours)
  end

  def test_report_two_criterias
    get :show, :project_id => 1, :columns => 'month', :from => "2007-01-01", :to => "2007-12-31", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
  end

  def test_report_one_day
    get :show, :project_id => 1, :columns => 'day', :from => "2007-03-23", :to => "2007-03-23", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "4.25", "%.2f" % assigns(:total_hours)
  end

  def test_report_at_issue_level
    get :show, :project_id => 1, :work_package_id => 1, :columns => 'month', :from => "2007-01-01", :to => "2007-12-31", :criterias => ["member", "activity"]
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "154.25", "%.2f" % assigns(:total_hours)
    assert_tag :form,
      :attributes => {:action => work_package_time_entries_report_path(1), :id => 'query_form'}
  end

  def test_report_custom_field_criteria
    get :show, :project_id => 1, :criterias => ['project', 'cf_1', 'cf_7']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_not_nil assigns(:criterias)
    assert_equal 3, assigns(:criterias).size
    assert_equal "162.90", "%.2f" % assigns(:total_hours)
    # Custom field column
    assert_tag :tag => 'th', :content => 'Database'
    # Custom field row
    assert_tag :tag => 'td', :content => 'MySQL',
                             :sibling => { :tag => 'td', :attributes => { :class => 'hours' },
                                                         :child => { :tag => 'span', :attributes => { :class => 'hours hours-int' },
                                                                                     :content => '1' }}
    # Second custom field column
    assert_tag :tag => 'th', :content => 'Billable'
  end

  def test_report_one_criteria_no_result
    get :show, :project_id => 1, :columns => 'week', :from => "1998-04-01", :to => "1998-04-30", :criterias => ['project']
    assert_response :success
    assert_template 'report'
    assert_not_nil assigns(:total_hours)
    assert_equal "0.00", "%.2f" % assigns(:total_hours)
  end

  def test_report_all_projects_csv_export
    get :show, :columns => 'month', :from => "2007-01-01", :to => "2007-06-30", :criterias => ["project", "member", "activity"], :format => "csv"
    assert_response :success
    assert_match(/text\/csv/, @response.content_type)
    lines = @response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end

  def test_report_csv_export
    get :show, :project_id => 1, :columns => 'month', :from => "2007-01-01", :to => "2007-06-30", :criterias => ["project", "member", "activity"], :format => "csv"
    assert_response :success
    assert_match(/text\/csv/, @response.content_type)
    lines = @response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end

end
