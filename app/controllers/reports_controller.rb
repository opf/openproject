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
  menu_item :issues
  before_filter :find_project, :authorize

  def issue_report
    @statuses = IssueStatus.find(:all, :order => 'position')
    
    @trackers = @project.trackers
    @versions = @project.shared_versions.sort
    @priorities = IssuePriority.all
    @categories = @project.issue_categories
    @assignees = @project.members.collect { |m| m.user }.sort
    @authors = @project.members.collect { |m| m.user }.sort
    @subprojects = @project.descendants.active
    issues_by_tracker
    issues_by_version
    issues_by_priority
    issues_by_category
    issues_by_assigned_to
    issues_by_author
    issues_by_subproject
      
    render :template => "reports/issue_report"
  end  

  def issue_report_details
    @statuses = IssueStatus.find(:all, :order => 'position')

    case params[:detail]
    when "tracker"
      @field = "tracker_id"
      @rows = @project.trackers
      @data = issues_by_tracker
      @report_title = l(:field_tracker)
    when "version"
      @field = "fixed_version_id"
      @rows = @project.shared_versions.sort
      @data = issues_by_version
      @report_title = l(:field_version)
    when "priority"
      @field = "priority_id"
      @rows = IssuePriority.all
      @data = issues_by_priority
      @report_title = l(:field_priority)
    when "category"
      @field = "category_id"
      @rows = @project.issue_categories
      @data = issues_by_category
      @report_title = l(:field_category)
    when "assigned_to"
      @field = "assigned_to_id"
      @rows = @project.members.collect { |m| m.user }.sort
      @data = issues_by_assigned_to
      @report_title = l(:field_assigned_to)
    when "author"
      @field = "author_id"
      @rows = @project.members.collect { |m| m.user }.sort
      @data = issues_by_author
      @report_title = l(:field_author)
    when "subproject"
      @field = "project_id"
      @rows = @project.descendants.active
      @data = issues_by_subproject
      @report_title = l(:field_subproject)
    end

    respond_to do |format|
      if @field
        format.html {}
      else
        format.html { redirect_to :action => 'issue_report', :id => @project }
      end
    end
  end
private
  def issues_by_tracker
    @issues_by_tracker ||= Issue.by_tracker(@project)
  end

  def issues_by_version
    @issues_by_version ||= Issue.by_version(@project)
  end
  	
  def issues_by_priority    
    @issues_by_priority ||= Issue.by_priority(@project)
  end
	
  def issues_by_category   
    @issues_by_category ||= Issue.by_category(@project)
  end
  
  def issues_by_assigned_to
    @issues_by_assigned_to ||= Issue.by_assigned_to(@project)
  end
  
  def issues_by_author
    @issues_by_author ||= Issue.by_author(@project)
  end
  
  def issues_by_subproject
    @issues_by_subproject ||= Issue.by_subproject(@project)
    @issues_by_subproject ||= []
  end
end
