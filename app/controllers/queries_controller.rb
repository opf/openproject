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

class QueriesController < ApplicationController
  menu_item :issues
  before_filter :find_query, :except => :new
  before_filter :find_optional_project, :only => :new

  def new
    @query = Query.new(params[:query])
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.display_subprojects = params[:display_subprojects] if params[:display_subprojects].present?
    @query.user = User.current
    @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?

    @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v]) if params[:fields] || params[:f]
    @query.group_by ||= params[:group_by]
    @query.column_names = params[:c] if params[:c]
    @query.column_names = nil if params[:default_columns]

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
      @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v]) if params[:fields] || params[:f]
      @query.attributes = params[:query]
      @query.project = nil if params[:query_is_for_all]
      @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.group_by ||= params[:group_by]
      @query.column_names = params[:c] if params[:c]
      @query.column_names = nil if params[:default_columns]

      if @query.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
      end
    end
  end

  def destroy
    @query.destroy if request.post?
    redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :set_filter => 1
  end

private
  def find_query
    @query = Query.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    render_403 unless User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
