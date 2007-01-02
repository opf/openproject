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

class QueriesController < ApplicationController
  layout 'base'
  before_filter :require_login, :find_query

  def edit
    if request.post?
      @query.filters = {}
      params[:fields].each do |field|
        @query.add_filter(field, params[:operators][field], params[:values][field])
      end if params[:fields]
      @query.attributes = params[:query]
          
      if @query.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :controller => 'projects', :action => 'list_issues', :id => @project, :query_id => @query
      end
    end
  end

  def destroy
    @query.destroy if request.post?
    redirect_to :controller => 'reports', :action => 'issue_report', :id => @project
  end
  
private
  def find_query
    @query = Query.find(params[:id])
    @project = @query.project
    # check if user is allowed to manage queries (same permission as add_query)
    authorize('projects', 'add_query')
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
