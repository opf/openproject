#-- encoding: UTF-8
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

class TypesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_filter :require_admin, :except => [:index, :show, :paginate_planning_element_types]

  def index
    @types = Type.without_standard
                 .page(params[:page])
                 .per_page(per_page_param)

    render :action => "index", :layout => false if request.xhr?
  end

  def type
    @type
  end

  def new
    @type = Type.new(params[:type])
    @types = Type.find(:all, :order => 'position')
    @projects = Project.find(:all)
  end

  def create
    @type = Type.new(permitted_params.type)
    if @type.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Type.find_by_id(params[:copy_workflow_from]))
        @type.workflows.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @types = Type.find(:all, :order => 'position')
      @projects = Project.find(:all)
      render :action => 'new'
    end
  end

  def edit
    @projects = Project.all
    @type  = Type.find(params[:id])
  end

  def update
    @type = Type.find(params[:id])

    if @type.update_attributes(permitted_params.type)
      redirect_to types_path, :notice => t(:notice_successful_update)
    else
      @projects = Project.all
      render :action => 'edit'
    end
  end

  def move
    @type = Type.find(params[:id])

    if @type.update_attributes(permitted_params.type_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('type_could_not_be_saved')
      render :action => 'edit'
    end
    redirect_to types_path
  end

  def destroy
    @type = Type.find(params[:id])
    # types cannot be deleted when they have work packages
    # put that into the model and do a `if @type.destroy`
    if @type.work_packages.empty?
      @type.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = t(:error_can_not_delete_type)
    end
    redirect_to :action => 'index'
  end
end
