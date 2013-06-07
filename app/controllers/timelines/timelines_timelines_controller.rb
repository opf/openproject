#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Timelines::TimelinesTimelinesController < ApplicationController
  unloadable
  helper :timelines

  before_filter :find_project_by_project_id
  before_filter :authorize

  menu_item :timelines_reports

  def index
    @timeline = @project.timelines_timelines.first
    if @timeline.nil?
      redirect_to new_timelines_project_timeline_path(@project)
    else
      redirect_to timelines_project_timeline_path(@project, @timeline)
    end
  end

  def show
    @visible_timelines = @project.timelines_timelines.all
    @timeline = @project.timelines_timelines.find(params[:id])
  end

  def new
    @timeline = @project.timelines_timelines.build
  end

  def create
    remove_blank_options

    @timeline = @project.timelines_timelines.build(params[:timeline])

    if @timeline.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to timelines_project_timeline_path(@project, @timeline)
    else
      render :action => "new"
    end
  end

  def edit
    @timeline = @project.timelines_timelines.find(params[:id])
  end

  def update
    @timeline = @project.timelines_timelines.find(params[:id])

    if @timeline.update_attributes(params[:timeline])
      flash[:notice] = l(:notice_successful_update)
      redirect_to timelines_project_timeline_path(@project, @timeline)
    else
      render :action => "edit"
    end
  end

  def confirm_destroy
    @timeline = @project.timelines_timelines.find(params[:id])
  end

  def destroy
    @timeline = @project.timelines_timelines.find(params[:id])
    @timeline.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to timelines_project_timelines_path @project
  end

  protected

  def default_breadcrumb
    l('timelines.project_menu.timelines')
  end

  def remove_blank_options
    options = params[:timeline][:options] || {}

    options.each do |k, v|
      options[k] = v.reject(&:blank?) if v.is_a? Array
    end

    params[:timeline][:options] = options
  end
end
