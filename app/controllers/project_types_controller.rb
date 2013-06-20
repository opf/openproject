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

class ProjectTypesController < ApplicationController
  extend Pagination::Controller
  paginate_model ProjectType

  unloadable
  helper :timelines

  before_filter :disable_api
  before_filter :check_permissions
  accept_key_auth :index, :show

  helper :timelines
  layout 'admin'

  def index
    @project_types = ProjectType.all
    respond_to do |format|
      format.html
    end
  end

  def new
    @project_type = ProjectType.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @project_type = ProjectType.new(permitted_params.project_type)

    if @project_type.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_types_path
    else
      flash.now[:error] = l('timelines.project_type_could_not_be_saved')
      render :action => 'new'
    end
  end

  def show
    @project_type = ProjectType.find(params[:id])
    respond_to do |format|
    end
  end

  def edit
    @project_type = ProjectType.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @project_type = ProjectType.find(params[:id])

    if @project_type.update_attributes(permitted_params.project_type)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_types_path
    else
      flash.now[:error] = l('timelines.project_type_could_not_be_saved')
      render :action => :edit
    end
  end

  def confirm_destroy
    @project_type = ProjectType.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @project_type = ProjectType.find(params[:id])
    flash[:notice] = l(:notice_successful_delete) if @project_type.destroy
    redirect_to project_types_path
  end

  def move
    @project_type = ProjectType.find(params[:id])

    if @project_type.update_attributes(permitted_params.project_type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('timelines.project_type_could_not_be_saved')
      render :action => 'edit'
    end
    redirect_to project_types_path
  end

  protected

  def default_breadcrumb
    l('timelines.admin_menu.project_types')
  end

  def check_permissions
    render_403 unless readonly_api_request or User.current.allowed_to_globally?(:edit_timelines)
  end

  def readonly_api_request
    api_request? and %w[index show].include? params[:action]
  end
end
