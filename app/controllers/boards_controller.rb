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

class BoardsController < ApplicationController
  default_search_scope :messages
  before_action :find_project_by_project_id,
                :authorize
  before_action :new_board, only: [:new, :create]
  before_action :find_board_if_available, except: [:index]
  accept_key_auth :index, :show

  include SortHelper
  include WatchersHelper
  include PaginationHelper
  include OpenProject::ClientPreferenceExtractor

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
    sort_init 'updated_on', 'desc'
    sort_update 'created_on' => "#{Message.table_name}.created_on",
                'replies' => "#{Message.table_name}.replies_count",
                'updated_on' => "#{Message.table_name}.updated_on"

    respond_to do |format|
      format.html do
        set_topics

        gon.rabl template: 'app/views/messages/index.rabl'
        gon.project_id = @project.id
        gon.activity_modul_enabled = @project.module_enabled?('activity')
        gon.board_id = @board.id
        gon.sort_column = 'updated_on'
        gon.sort_direction = 'desc'
        gon.total_count = @board.topics.count
        gon.settings = client_preferences

        @message = Message.new
        render action: 'show', layout: !request.xhr?
      end
      format.json do
        set_topics

        gon.rabl template: 'app/views/messages/index.rabl'

        render template: 'messages/index'
      end
      format.atom do
        @messages = @board.messages.order(["#{Message.table_name}.sticked_on ASC", sort_clause].compact.join(', '))
                    .includes(:author, :board)
                    .limit(Setting.feeds_limit.to_i)

        render_feed(@messages, title: "#{@project}: #{@board}")
      end
    end
  end

  def set_topics
    @topics =  @board.topics.order(["#{Message.table_name}.sticked_on ASC", sort_clause].compact.join(', '))
               .includes(:author,  last_reply: :author)
               .page(params[:page])
               .per_page(per_page_param)
  end

  def new
  end

  def create
    if @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @board.update_attributes(permitted_params.board)
      flash[:notice] = l(:notice_successful_update)
      redirect_to_settings_in_projects
    else
      render :edit
    end
  end

  def move
    if @board.update_attributes(permitted_params.board_move)
      flash[:notice] = l(:notice_successful_update)
    else
      flash.now[:error] = l('board_could_not_be_saved')
      render action: 'edit'
    end
    redirect_to controller: :projects,
                action: 'settings',
                tab: 'boards',
                id: @board.project_id
  end

  def destroy
    @board.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to_settings_in_projects
  end

  private

  def redirect_to_settings_in_projects
    redirect_to controller: '/projects', action: 'settings', id: @project, tab: 'boards'
  end

  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new_board
    @board = Board.new(permitted_params.board?)
    @board.project = @project
  end
end
