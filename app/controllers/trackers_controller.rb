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

class TrackersController < ApplicationController
  layout 'base'
  before_filter :require_admin

  def index
    list
    render :action => 'list' unless request.xhr?
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :move ], :redirect_to => { :action => :list }

  def list
    @tracker_pages, @trackers = paginate :trackers, :per_page => 10, :order => 'position'
    render :action => "list", :layout => false if request.xhr?
  end

  def new
    @tracker = Tracker.new(params[:tracker])
    if request.post? and @tracker.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Tracker.find_by_id(params[:copy_workflow_from]))
        copy_from.workflows.each do |w|
          @tracker.workflows << w.clone
        end
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'list'
    end
    @trackers = Tracker.find :all
  end

  def edit
    @tracker = Tracker.find(params[:id])
    if request.post? and @tracker.update_attributes(params[:tracker])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list'
    end
  end

  def move
    @tracker = Tracker.find(params[:id])
    case params[:position]
    when 'highest'
      @tracker.move_to_top
    when 'higher'
      @tracker.move_higher
    when 'lower'
      @tracker.move_lower
    when 'lowest'
      @tracker.move_to_bottom
    end if params[:position]
    redirect_to :action => 'list'
  end
  
  def destroy
    @tracker = Tracker.find(params[:id])
    unless @tracker.issues.empty?
      flash[:error] = "This tracker contains issues and can\'t be deleted."
    else
      @tracker.destroy
    end
    redirect_to :action => 'list'
  end  
end
