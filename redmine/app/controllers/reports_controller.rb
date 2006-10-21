# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class ReportsController < ApplicationController
 	layout 'base'
	before_filter :find_project, :authorize
  
  def issue_report
    @statuses = IssueStatus.find_all
    
    case params[:detail]
    when "tracker"
      @field = "tracker_id"
      @rows = Tracker.find_all
      @data = issues_by_tracker
      @report_title = l(:field_tracker)
      render :template => "reports/issue_report_details"
    when "priority"
      @field = "priority_id"
      @rows = Enumeration::get_values('IPRI')
      @data = issues_by_priority
      @report_title = l(:field_priority)
      render :template => "reports/issue_report_details"   
    when "category"
      @field = "category_id"
      @rows = @project.issue_categories
      @data = issues_by_category
      @report_title = l(:field_category)
      render :template => "reports/issue_report_details"   
    when "author"
      @field = "author_id"
      @rows = @project.members.collect { |m| m.user }
      @data = issues_by_author
      @report_title = l(:field_author)
      render :template => "reports/issue_report_details"  
    else
      @trackers = Tracker.find(:all)
      @priorities = Enumeration::get_values('IPRI')
      @categories = @project.issue_categories
      @authors = @project.members.collect { |m| m.user }
      issues_by_tracker
      issues_by_priority
      issues_by_category
      issues_by_author
      render :template => "reports/issue_report"
    end
  end  
  
private
	# Find project of id params[:id]
	def find_project
		@project = Project.find(params[:id])		
	end
	
	def issues_by_tracker
    @issues_by_tracker ||= 
        ActiveRecord::Base.connection.select_all("select    s.id as status_id, 
                                                  s.is_closed as closed, 
                                                  t.id as tracker_id,
                                                  count(i.id) as total 
                                                from 
                                                  issues i, issue_statuses s, trackers t
                                                where 
                                                  i.status_id=s.id 
                                                  and i.tracker_id=t.id
                                                  and i.project_id=#{@project.id}
                                                group by s.id, s.is_closed, t.id")	
	end
	
	def issues_by_priority    
    @issues_by_priority ||= 
      ActiveRecord::Base.connection.select_all("select    s.id as status_id, 
                                                  s.is_closed as closed, 
                                                  p.id as priority_id,
                                                  count(i.id) as total 
                                                from 
                                                  issues i, issue_statuses s, enumerations p
                                                where 
                                                  i.status_id=s.id 
                                                  and i.priority_id=p.id
                                                  and i.project_id=#{@project.id}
                                                group by s.id, s.is_closed, p.id")	
	end
	
	def issues_by_category   
    @issues_by_category ||= 
      ActiveRecord::Base.connection.select_all("select    s.id as status_id, 
                                                  s.is_closed as closed, 
                                                  c.id as category_id,
                                                  count(i.id) as total 
                                                from 
                                                  issues i, issue_statuses s, issue_categories c
                                                where 
                                                  i.status_id=s.id 
                                                  and i.category_id=c.id
                                                  and i.project_id=#{@project.id}
                                                group by s.id, s.is_closed, c.id")	
	end
	
	def issues_by_author
    @issues_by_author ||= 
      ActiveRecord::Base.connection.select_all("select    s.id as status_id, 
                                                  s.is_closed as closed, 
                                                  a.id as author_id,
                                                  count(i.id) as total 
                                                from 
                                                  issues i, issue_statuses s, users a
                                                where 
                                                  i.status_id=s.id 
                                                  and i.author_id=a.id
                                                  and i.project_id=#{@project.id}
                                                group by s.id, s.is_closed, a.id")	
	end
end
