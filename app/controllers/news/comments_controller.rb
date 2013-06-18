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

class News::CommentsController < ApplicationController
  default_search_scope :news
  model_object Comment, :scope => [News => :commented]
  before_filter :find_object_and_scope
  before_filter :authorize

  def create
    @comment = Comment.new(params[:comment])
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to news_path(@news)
  end

  def destroy
    @comment.destroy
    redirect_to news_path(@news)
  end
end
