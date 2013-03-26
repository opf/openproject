#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class TrackersController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def index
    @tracker_pages, @trackers = paginate :trackers, :per_page => 10, :order => 'position'
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @tracker = Tracker.new(params[:tracker])
    @trackers = Tracker.find(:all, :order => 'position')
    @projects = Project.find(:all)
  end

  def create
    @tracker = Tracker.new(params[:tracker])
    if @tracker.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Tracker.find_by_id(params[:copy_workflow_from]))
        @tracker.workflows.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @trackers = Tracker.find(:all, :order => 'position')
      @projects = Project.find(:all)
      render :action => 'new'
    end
  end

  def edit
    @projects = Project.all
    @tracker  = Tracker.find(params[:id])
  end

  def update
    @tracker = Tracker.find(params[:id])
    if @tracker.update_attributes(params[:tracker])
      redirect_to trackers_path, :notice => t(:notice_successful_update)
    else
      @projects = Project.all
      render :action => 'edit'
    end
  end

  def destroy
    @tracker = Tracker.find(params[:id])
    # trackers cannot be deleted when they have issue
    # put that into the model and do a `if @tracker.destroy`
    if @tracker.issues.empty?
      @tracker.destroy
    else
      flash[:error] = t(:error_can_not_delete_tracker)
    end
    redirect_to :action => 'index'
  end
end
