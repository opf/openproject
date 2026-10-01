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

class News::CommentsController < ApplicationController
  default_search_scope :news

  before_action :find_news_and_project
  before_action :find_comment, only: [:destroy]
  before_action :authorize

  def create
    @comment = Comment.new(permitted_params.comment)
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = I18n.t(:label_comment_added)
    end

    redirect_to project_news_path(@project, @news), status: :see_other
  end

  def destroy
    @comment.destroy!
    redirect_to project_news_path(@project, @news), status: :see_other
  end

  private

  def find_comment
    @comment = @news.comments.find(params[:id])
  end

  def find_news_and_project
    @project = Project.visible.find(params[:project_id])
    @news = @project.news.visible.find(params[:news_id])
  end
end
