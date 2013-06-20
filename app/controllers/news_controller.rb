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

class NewsController < ApplicationController
  include PaginationHelper

  default_search_scope :news
  model_object News

  before_filter :disable_api
  before_filter :find_model_object, :except => [:new, :create, :index]
  before_filter :find_project_from_association, :except => [:new, :create, :index]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :except => [:index]
  before_filter :find_optional_project, :only => :index
  accept_key_auth :index

  menu_item :new_news, :only => [:new, :create]

  def index
    scope = @project ? @project.news.visible : News.visible

    @newss = scope.includes(:author, :project)
                  .order("#{News.table_name}.created_on DESC")
                  .page(params[:page])
                  .per_page(per_page_param)

    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.atom { render_feed(@newss, :title => (@project ? @project.name : Setting.app_title) + ": #{l(:label_news_plural)}") }
    end
  end

  def show
    @comments = @news.comments
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def new
    @news = News.new(:project => @project, :author => User.current)
  end

  def create
    @news = News.new(:project => @project, :author => User.current)
    @news.safe_attributes = params[:news]
    if @news.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => '/news', :action => 'index', :project_id => @project
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @news.safe_attributes = params[:news]
    if @news.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end

  def destroy
    @news.destroy
    redirect_to :action => 'index', :project_id => @project
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
