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

class FeedsController < ApplicationController
  before_filter :find_scope
  session :off

  helper :issues
  include IssuesHelper
  helper :custom_fields
  include CustomFieldsHelper
    
  # news feeds
  def news
    News.with_scope(:find => @find_options) do
      @news = News.find :all, :order => "#{News.table_name}.created_on DESC", :include => [ :author, :project ]
    end
    headers["Content-Type"] = "application/rss+xml"
    render :action => 'news_atom' if 'atom' == params[:format]
  end
  
  # issue feeds
  def issues
    if @project && params[:query_id]
      query = Query.find(params[:query_id])
      query.executed_by = @user
      # ignore query if it's not valid
      query = nil unless query.valid?
      # override with query conditions
      @find_options[:conditions] = query.statement if query.valid? and @project == query.project
    end

    Issue.with_scope(:find => @find_options) do
      @issues = Issue.find :all, :include => [:project, :author, :tracker, :status, :custom_values], 
                                 :order => "#{Issue.table_name}.created_on DESC"
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (query ? query.name : l(:label_reported_issues))
    headers["Content-Type"] = "application/rss+xml"
    render :action => 'issues_atom' if 'atom' == params[:format]
  end
  
  # issue changes feeds
  def history    
    if @project && params[:query_id]
      query = Query.find(params[:query_id])
      query.executed_by = @user
      # ignore query if it's not valid
      query = nil unless query.valid?
      # override with query conditions
      @find_options[:conditions] = query.statement if query.valid? and @project == query.project
    end

    Journal.with_scope(:find => @find_options) do
      @journals = Journal.find :all, :include => [ :details, :user, {:issue => [:project, :author, :tracker, :status, :custom_values]} ], 
                                     :order => "#{Journal.table_name}.created_on DESC"
    end
    
    @title = (@project ? @project.name : Setting.app_title) + ": " + (query ? query.name : l(:label_reported_issues))
    headers["Content-Type"] = "application/rss+xml"
    render :action => 'history_atom' if 'atom' == params[:format]
  end
   
private
  # override for feeds specific authentication
  def check_if_login_required
    @user = User.find_by_rss_key(params[:key])
    render(:nothing => true, :status => 403) and return false if !@user && Setting.login_required?
  end
  
  def find_scope
    if params[:project_id]
      # project feed
      # check if project is public or if the user is a member
      @project = Project.find(params[:project_id])
      render(:nothing => true, :status => 403) and return false unless @project.is_public? || (@user && @user.role_for_project(@project))
      scope = ["#{Project.table_name}.id=?", params[:project_id].to_i]
    else
      # global feed
      scope = ["#{Project.table_name}.is_public=?", true]
    end
    @find_options = {:conditions => scope, :limit => Setting.feeds_limit.to_i}
    return true
  end
end
