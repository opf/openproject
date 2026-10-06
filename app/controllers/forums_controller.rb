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

class ForumsController < ApplicationController
  default_search_scope :messages
  before_action :find_project_by_project_id
  before_action :new_forum, only: %i[new create]
  before_action :find_forum, only: %i[show edit update move destroy]

  before_action :authorize

  accept_key_auth :show

  include SortHelper
  include PaginationHelper
  include OpTurbo::ComponentStream

  def index
    @forums = @project.forums.includes(last_message: :author)
  end

  current_menu_item [:index, :show] do
    :forums
  end

  def show # rubocop:disable Metrics/AbcSize
    sort_init "updated_at", "desc"
    sort_update "created_at" => "#{Message.table_name}.created_at",
                "replies" => "#{Message.table_name}.replies_count",
                "updated_at" => "#{Message.table_name}.updated_at"

    respond_to do |format|
      format.html do
        set_topics
        @message = Message.new
        render action: "show", layout: !request.xhr?
      end
      # The JSON template does not exist anymore, this never rendered
      #    format.json do
      #      set_topics
      #      render template: "messages/index"
      #    end
      format.atom do
        @messages = @forum
                    .messages
                    .order(["#{Message.table_name}.sticked_on ASC", sort_clause].compact.join(", "))
                    .includes(:author, :forum)
                    .limit(Setting.feeds_limit.to_i)

        render_feed(@messages, title: "#{@project}: #{@forum}")
      end
    end
  end

  def set_topics
    @topics = @forum
              .topics
              .order(["#{Message.table_name}.sticked_on ASC", sort_clause].compact.join(", "))
              .includes(:author, last_reply: :author)
              .page(page_param)
              .per_page(per_page_param)
  end

  def new; end

  def edit; end

  def create
    if @forum.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_forums_path(@project)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @forum.update(permitted_params.forum)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_forums_path(@project)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def move
    moved = menu_move? ? move_in_direction : move_after_anchor

    if moved
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
      update_via_turbo_stream(component: index_component, method: :morph)
    else
      error_key = menu_move? ? "forums.index.could_not_be_moved" : :error_invalid_list_move_anchor
      render_error_flash_message_via_turbo_stream(message: I18n.t(error_key))
    end

    respond_with_turbo_streams(status: moved ? :ok : :unprocessable_entity)
  end

  def destroy
    @forum.destroy!

    flash[:notice] = I18n.t(:notice_successful_delete)
    redirect_to project_forums_path(@project), status: :see_other
  end

  private

  def index_component
    Forums::IndexComponent.new(forums: @project.forums.includes(last_message: :author), project: @project)
  end

  def move_in_direction
    move_to = permitted_params.forum_move[:move_to]

    move_to.in?(%w[highest higher lower lowest]) && @forum.update(move_to:)
  end

  def menu_move?
    params.key?(:forum)
  end

  def move_after_anchor
    valid_drop_request? && @forum.move_after_anchor(drop_params[:prev_id], scope: @project.forums)
  end

  def valid_drop_request?
    drop_params[:list_type] == Forum::SORTABLE_LIST_TYPE &&
      params[:list_id].blank? &&
      (params[:list_id].nil? || drop_params.key?(:list_id)) &&
      drop_params.key?(:prev_id)
  end

  def drop_params
    @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
  end

  def find_forum
    @forum = @project.forums.find(params.expect(:id))
  end

  def new_forum
    @forum = Forum.new(permitted_params.forum?)
    @forum.project = @project
  end
end
