# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

class NewsController < ApplicationController
  include PaginationHelper
  include Layout

  default_search_scope :news

  before_action :load_and_authorize_in_optional_project
  before_action :find_news_object, except: %i[new create index]
  before_action :authorize

  accept_key_auth :index

  def index # rubocop:disable Metrics/AbcSize
    scope = @project ? @project.news : News.visible

    @news = scope.merge(News.latest_for(current_user, count: 0))
                  .page(page_param)
                  .per_page(per_page_param)

    respond_to do |format|
      format.html do
        render locals: { menu_name: project_or_global_menu }
      end
      format.atom do
        render_feed(@news,
                    title: (@project ? @project.name : Setting.app_title) + ": #{I18n.t(:label_news_plural)}")
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

  def edit; end

  def create
    call = News::CreateService
      .new(user: current_user)
      .call(permitted_params.news.merge(project: @project))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to controller: "/news", action: "index", project_id: @project
    else
      @news = call.result
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    call = News::UpdateService
      .new(model: @news, user: current_user)
      .call(permitted_params.news.merge(project: @project))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_news_path(@project, @news)
    else
      @news = call.result
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    call = News::DeleteService
      .new(model: @news, user: current_user)
      .call

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_delete)
    else
      call.apply_flash_message!(flash)
    end

    redirect_to action: "index", project_id: @project, status: :see_other
  end

  private

  def find_news_object
    if @project
      @news = @project.news.visible.find(params[:id].to_i)
    else
      @news = News.visible.find(params[:id].to_i)
      @project = @news.project
    end
  end
end
