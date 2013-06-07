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

class Timelines::TimelinesProjectAssociationsController < ApplicationController
  unloadable
  helper :timelines

  before_filter :find_project_by_project_id
  before_filter :authorize
  before_filter :check_allows_association

  accept_key_auth :index, :show

  menu_item :timelines_project_associations

  def index
    respond_to do |format|
      format.html do
        # TODO:
        #   Project types should be ordered by position
        #   Projects and associations should be ordered by project tree
        @project_types = [nil] + Timelines::ProjectType.all
        @project_associations_by_type = @project.timelines_project_associations_by_type
      end

      format.api do
        @project_associations = @project.timelines_project_associations.visible
      end
    end
  end

  def available_projects
    available_projects = @project.timelines_associated_project_candidates
    respond_to do |format|
      format.html { render_404 }
      format.api {
        @elements = Project.project_level_list(Project.visible)
        @disabled = Project.visible - available_projects
      }
    end
  end

  def new
    @project_association = Timelines::ProjectAssociation.new(params[:project_association])
    @project_association.project_a = @project
    @associated_project_candidates_by_type = @project.timelines_associated_project_candidates_by_type
  end

  def create
    @project_association = Timelines::ProjectAssociation.new(params[:project_association])
    @project_association.project_a = @project
    @project_association.project_b_id = params[:project_association_select][:project_b_id]

    check_visibility

    if @project_association.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to timelines_project_project_associations_path(@project)
    else
      render :action => 'new'
    end
  end

  def show
    @project_association = @project.timelines_project_associations.find(params[:id])
    check_visibility

    respond_to do |format|
      format.api
    end
  end

  def edit
    @project_association = @project.timelines_project_associations.find(params[:id])
    check_visibility

    respond_to do |format|
      format.html
    end
  end

  def update
    @project_association = @project.timelines_project_associations.find(params[:id])
    check_visibility

    @project_association.description =  params[:project_association][:description]

    check_visibility # since projects may not be edited by mass-assignement,
                     # this check should be superfluous ... but who knows?!?

    if @project_association.projects.include?(@project) and @project_association.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to timelines_project_project_associations_path(@project)
    else
      render :action => 'edit'
    end
  end

  def confirm_destroy
    @project_association = @project.timelines_project_associations.find(params[:id])
    check_visibility

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @project_association = @project.timelines_project_associations.find(params[:id])
    check_visibility

    @project_association.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to timelines_project_project_associations_path(@project)
  end

  protected

  def check_allows_association
    render_404 unless @project.timelines_allows_association?
  end

  def check_visibility
    raise ActiveRecord::RecordNotFound unless @project_association.visible?
  end

  def default_breadcrumb
    l('timelines.project_menu.project_associations')
  end
end
