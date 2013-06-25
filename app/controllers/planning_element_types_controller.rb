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

class PlanningElementTypesController < ApplicationController
  unloadable
  helper :timelines

  before_filter :disable_api
  before_filter :determine_base
  before_filter :check_permissions
  before_filter :ensure_global_scope, :except => [:index, :show]

  accept_key_auth :index, :show

  helper :timelines
  layout 'admin'

  extend Pagination::Controller
  paginate_model PlanningElementType

  def index
    @planning_element_types = @base.all
    respond_to do |format|
      format.html { render_404 if @project }
    end
  end

  def show
    @planning_element_type = @base.find(params[:id])
    respond_to do |format|
      format.html { render_404 }
    end
  end

  def new
    @planning_element_type = PlanningElementType.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @planning_element_type = PlanningElementType.new(permitted_params.planning_element_type)
    if @planning_element_type.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to planning_element_types_path
    else
      flash.now[:error] = l('timelines.planning_element_type_could_not_be_saved')
      render :action => "new"
    end
  end

  def edit
    @planning_element_type = @base.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @planning_element_type = @base.find(params[:id])

    if @planning_element_type.update_attributes(permitted_params.planning_element_type)
      flash[:notice] = l(:notice_successful_update)
      redirect_to planning_element_types_path
    else
      flash.now[:error] = l('timelines.planning_element_type_could_not_be_saved')
      render :action => 'edit'
    end
  end

  def move
    @planning_element_type = @base.find(params[:id])

    if @planning_element_type.update_attributes(permitted_params.planning_element_type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      render :action => 'edit'
    end
    redirect_to planning_element_types_path
  end

  def confirm_destroy
    @planning_element_type = @base.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @planning_element_type = @base.find(params[:id])
    @planning_element_type.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to planning_element_types_path
  end

  protected

  def determine_base
    if params[:project_id]
      @project = Project.find(params[:project_id])
      @base = @project.planning_element_types
    else
      @base = PlanningElementType
    end
  end

  def check_permissions
    if @base == PlanningElementType
      render_403 unless readonly_api_request or User.current.allowed_to_globally?(:edit_timelines)
    else
      authorize
    end
  end

  def ensure_global_scope
    render_404 if @project
  end

  def readonly_api_request
    api_request? and %w[index show].include? params[:action]
  end

  def default_breadcrumb
    l('timelines.admin_menu.planning_element_types')
  end
end
