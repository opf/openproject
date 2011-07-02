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

class BoardsController < ApplicationController
  default_search_scope :messages
  before_filter :find_project, :find_board_if_available, :authorize
  accept_key_auth :index, :show

  include MessagesHelper
  include SortHelper
  include WatchersHelper

  def index
    @boards = @project.boards
    render_404 if @boards.empty?
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end

  def show
    respond_to do |format|
      format.html {
        sort_init 'updated_on', 'desc'
        sort_update	'created_on' => "#{Message.table_name}.created_on",
                    'replies' => "#{Message.table_name}.replies_count",
                    'updated_on' => "#{Message.table_name}.updated_on"

        @topic_count = @board.topics.count
        @topic_pages = Paginator.new self, @topic_count, per_page_option, params['page']
        @topics =  @board.topics.find :all, :order => ["#{Message.table_name}.sticky DESC", sort_clause].compact.join(', '),
                                      :include => [:author, {:last_reply => :author}],
                                      :limit  =>  @topic_pages.items_per_page,
                                      :offset =>  @topic_pages.current.offset
        @message = Message.new
        render :action => 'show', :layout => !request.xhr?
      }
      format.atom {
        @messages = @board.messages.find :all, :order => 'created_on DESC',
                                               :include => [:author, :board],
                                               :limit => Setting.feeds_limit.to_i
        render_feed(@messages, :title => "#{@project}: #{@board}")
      }
    end
  end

  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :index }

  def new
    @board = Board.new(params[:board])
    @board.project = @project
    if request.post? && @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    end
  end

  def edit
    if request.post? && @board.update_attributes(params[:board])
      redirect_to_settings_in_projects
    end
  end

  def destroy
    @board.destroy
    redirect_to_settings_in_projects
  end

private
  def redirect_to_settings_in_projects
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'boards'
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
