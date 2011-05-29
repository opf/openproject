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

class NewsController < ApplicationController
  default_search_scope :news
  model_object News
  before_filter :find_model_object, :except => [:new, :create, :index]
  before_filter :find_project_from_association, :except => [:new, :create, :index]
  before_filter :find_project, :only => [:new, :create]
  before_filter :authorize, :except => [:index]
  before_filter :find_optional_project, :only => :index
  accept_key_auth :index
  
  
  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit =  10
    end
    
    scope = @project ? @project.news.visible : News.visible
    
    @news_count = scope.count
    @news_pages = Paginator.new self, @news_count, @limit, params['page']
    @offset ||= @news_pages.current.offset
    @newss = scope.all(:include => [:author, :project],
                                       :order => "#{News.table_name}.created_on DESC",
                                       :offset => @offset,
                                       :limit => @limit)
    
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
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
    if request.post?
      @news.attributes = params[:news]
      if @news.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'news', :action => 'index', :project_id => @project
      else
        render :action => 'new'
      end
    end
  end

  def edit
  end
  
  def update
    if request.put? and @news.update_attributes(params[:news])
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
