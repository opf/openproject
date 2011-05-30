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

class CommentsController < ApplicationController
  default_search_scope :news
  model_object News
  before_filter :find_model_object
  before_filter :find_project_from_association
  before_filter :authorize

  verify :method => :post, :only => :create, :render => {:nothing => true, :status => :method_not_allowed }
  def create
    @comment = Comment.new(params[:comment])
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end

    redirect_to :controller => 'news', :action => 'show', :id => @news
  end

  verify :method => :delete, :only => :destroy, :render => {:nothing => true, :status => :method_not_allowed }
  def destroy
    @news.comments.find(params[:comment_id]).destroy
    redirect_to :controller => 'news', :action => 'show', :id => @news
  end

  private

  # ApplicationController's find_model_object sets it based on the controller
  # name so it needs to be overriden and set to @news instead
  def find_model_object
    super
    @news = @object
    @comment = nil
    @news
  end

end
