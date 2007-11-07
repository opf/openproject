# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class BoardsController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize

  helper :messages
  include MessagesHelper
  helper :sort
  include SortHelper
  helper :watchers
  include WatchersHelper
 
  def index
    @boards = @project.boards
    # show the board if there is only one
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end

  def show
    sort_init "#{Message.table_name}.updated_on", "desc"
    sort_update	
      
    @topic_count = @board.topics.count
    @topic_pages = Paginator.new self, @topic_count, 25, params['page']
    @topics =  @board.topics.find :all, :order => sort_clause,
                                  :include => [:author, {:last_reply => :author}],
                                  :limit  =>  @topic_pages.items_per_page,
                                  :offset =>  @topic_pages.current.offset
    render :action => 'show', :layout => !request.xhr?
  end
  
  verify :method => :post, :only => [ :destroy ], :redirect_to => { :action => :index }

  def new
    @board = Board.new(params[:board])
    @board.project = @project
    if request.post? && @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'boards'
    end
  end

  def edit
    if request.post? && @board.update_attributes(params[:board])
      case params[:position]
      when 'highest'; @board.move_to_top
      when 'higher'; @board.move_higher
      when 'lower'; @board.move_lower
      when 'lowest'; @board.move_to_bottom
      end if params[:position]
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'boards'
    end
  end

  def destroy
    @board.destroy
    redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'boards'
  end
  
private
  def find_project
    @project = Project.find(params[:project_id])
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
