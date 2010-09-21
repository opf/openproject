# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class NewsController < ApplicationController
  default_search_scope :news
  model_object News
  before_filter :find_model_object, :except => [:new, :create, :index, :preview]
  before_filter :find_project_from_association, :except => [:new, :create, :index, :preview]
  before_filter :find_project, :only => [:new, :create, :preview]
  before_filter :authorize, :except => [:index, :preview]
  before_filter :find_optional_project, :only => :index
  accept_key_auth :index
  
  def index
    @news_pages, @newss = paginate :news,
                                   :per_page => 10,
                                   :conditions => Project.allowed_to_condition(User.current, :view_news, :project => @project),
                                   :include => [:author, :project],
                                   :order => "#{News.table_name}.created_on DESC"    
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.xml { render :xml => @newss.to_xml }
      format.json { render :json => @newss.to_json }
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

  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = l(:label_comment_added)
      redirect_to :action => 'show', :id => @news
    else
      show
      render :action => 'show'
    end
  end

  def destroy_comment
    @news.comments.find(params[:comment_id]).destroy
    redirect_to :action => 'show', :id => @news
  end

  def destroy
    @news.destroy
    redirect_to :action => 'index', :project_id => @project
  end
  
  def preview
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
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
