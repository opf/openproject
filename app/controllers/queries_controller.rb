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

class QueriesController < ApplicationController
  layout 'base'
  menu_item :issues
  before_filter :find_project, :authorize

  def index
    @queries = @project.queries.find(:all, 
                                     :order => "name ASC",
                                     :conditions => ["is_public = ? or user_id = ?", true, (User.current.logged? ? User.current.id : 0)])
  end
  
  def new
    @query = Query.new(params[:query])
    @query.project = @project
    @query.user = User.current
    @query.is_public = false unless current_role.allowed_to?(:manage_public_queries)
    @query.column_names = nil if params[:default_columns]
    
    params[:fields].each do |field|
      @query.add_filter(field, params[:operators][field], params[:values][field])
    end if params[:fields]
    
    if request.post? && params[:confirm] && @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
      return
    end
    render :layout => false if request.xhr?
  end
  
  def edit
    if request.post?
      @query.filters = {}
      params[:fields].each do |field|
        @query.add_filter(field, params[:operators][field], params[:values][field])
      end if params[:fields]
      @query.attributes = params[:query]
      @query.is_public = false unless current_role.allowed_to?(:manage_public_queries)
      @query.column_names = nil if params[:default_columns]
      
      if @query.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
      end
    end
  end

  def destroy
    @query.destroy if request.post?
    redirect_to :controller => 'queries', :project_id => @project
  end
  
private
  def find_project
    if params[:id]
      @query = Query.find(params[:id])
      @project = @query.project
      render_403 unless @query.editable_by?(User.current)
    else
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
