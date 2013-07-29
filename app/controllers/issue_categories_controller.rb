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

class IssueCategoriesController < ApplicationController
  menu_item :settings
  model_object IssueCategory
  before_filter :find_model_object, :except => [:new, :create]
  before_filter :find_project_from_association, :except => [:new, :create]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize

  def new
    @category = @project.issue_categories.build
  end

  def create
    @category = @project.issue_categories.build
    @category.safe_attributes = params[:category]

    if @category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller => '/projects', :action => 'settings', :tab => 'categories', :id => @project
        end
        format.js do
          render :locals => { :project => @project, :category => @category }
        end
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.js do
          render(:update) {|page| page.alert(@category.errors.full_messages.join('\n')) }
        end
      end
    end
  end

  def edit
    @category.safe_attributes = params[:category]
  end

  def update
    @category.safe_attributes = params[:category]
    if @category.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => '/projects', :action => 'settings', :tab => 'categories', :id => @project
    else
      render :action => 'edit'
    end
  end

  def destroy
    @issue_count = @category.work_packages.size
    if @issue_count == 0
      # No issue assigned to this category
      @category.destroy
      redirect_to :controller => '/projects', :action => 'settings', :id => @project, :tab => 'categories'
      return
    elsif params[:todo]
      reassign_to = @project.issue_categories.find_by_id(params[:reassign_to_id]) if params[:todo] == 'reassign'
      @category.destroy(reassign_to)
      redirect_to :controller => '/projects', :action => 'settings', :id => @project, :tab => 'categories'
      return
    end
    @categories = @project.issue_categories - [@category]
  end

private
  # Wrap ApplicationController's find_model_object method to set
  # @category instead of just @issue_category
  def find_model_object
    super
    @category = @object
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
