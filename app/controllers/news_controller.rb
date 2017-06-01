#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class NewsController < ApplicationController
  include PaginationHelper
  include OpenProject::Concerns::Preview

  default_search_scope :news

  before_action :disable_api
  before_action :find_news_object, except: [:new, :create, :index, :preview]
  before_action :find_project_from_association, except: [:new, :create, :index, :preview]
  before_action :find_project, only: [:new, :create]
  before_action :authorize, except: [:index, :preview]
  before_action :find_optional_project, only: [:index]
  accept_key_auth :index

  def index
    scope = @project ? @project.news : News.all

    @newss = scope.merge(News.latest_for(current_user, count: 0))
                  .page(params[:page])
                  .per_page(per_page_param)

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
      format.atom do
        render_feed(@newss,
                    title: (@project ? @project.name : Setting.app_title) + ": #{l(:label_news_plural)}")
      end
    end
  end

  current_menu_item :index do
    :news
  end

  def show
    @comments = @news.comments
    @comments.reverse_order if User.current.wants_comments_in_reverse_order?
  end

  def new
    @news = News.new(project: @project, author: User.current)
  end

  def create
    @news = News.new(project: @project, author: User.current)
    @news.attributes = permitted_params.news
    if @news.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to controller: '/news', action: 'index', project_id: @project
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @news.attributes = permitted_params.news
    if @news.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @news
    else
      render action: 'edit'
    end
  end

  def destroy
    @news.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: 'index', project_id: @project
  end

  protected

  def parse_preview_data
    parse_preview_data_helper :news, :description
  end

  def parse_preview_id
    params[:id].to_i
  end

  private

  def find_news_object
    @news = @object = News.find(params[:id].to_i)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

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
