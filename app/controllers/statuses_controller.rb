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

class StatusesController < ApplicationController
  include PaginationHelper
  include OpTurbo::ComponentStream

  layout "admin"

  before_action :require_admin

  def index
    @query = load_query
    @statuses = paginated_statuses
    @page_args = page_args
  end

  def new
    @status = Status.new
  end

  def edit
    @status = Status.find(params[:id])
  end

  def create
    @status = Status.new(permitted_params.status)
    if @status.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to action: "index"
    else
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @status = Status.find(params[:id])
    if @status.update(permitted_params.status)
      recompute_progress_values
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "index", status: :see_other
    else
      render action: :edit, status: :unprocessable_entity
    end
  end

  def destroy
    status = Status.find(params[:id])
    if status.is_default?
      flash[:error] = I18n.t(:error_unable_delete_default_status)
    else
      status.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
    end
    redirect_to action: "index", status: :see_other
  rescue StandardError
    flash[:error] = I18n.t(:error_unable_delete_status)
    redirect_to action: "index", status: :see_other
  end

  def move
    status = Status.find(params.expect(:id))
    moved = params.key?(:move_to) ? move_in_direction(status) : move_after_anchor(status)

    if moved
      render_move_success
    else
      error_key = params.key?(:move_to) ? "statuses.index.could_not_be_moved" : :error_invalid_list_move_anchor
      render_error_flash_message_via_turbo_stream(message: I18n.t(error_key))
    end

    respond_with_turbo_streams(status: moved ? :ok : :unprocessable_entity)
  end

  protected

  def render_move_success
    @query = Queries::Statuses::StatusQuery.new(user: current_user)
    render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
    update_via_turbo_stream(component: index_component, method: :morph)
  end

  def index_component
    Statuses::IndexComponent.new(statuses: paginated_statuses, query: @query, page_args:)
  end

  def load_query
    ParamsToQueryService.new(Status, current_user).call(params)
  end

  def paginated_statuses
    @query.results.page(page_param).per_page(per_page_param)
  end

  def page_args
    { page: page_param, per_page: per_page_param }
  end

  def move_in_direction(status)
    move_to = params[:move_to]

    move_to.in?(%w[highest higher lower lowest]) && status.update(move_to:)
  end

  def move_after_anchor(status)
    return false unless valid_drop_request?

    prev_id = drop_params[:prev_id]

    if prev_id.blank? && page_param > 1
      move_to_page_start(status)
    else
      status.move_after_anchor(prev_id, scope: Status.all)
    end
  end

  def move_to_page_start(status)
    statuses = Status.page(page_param).per_page(per_page_param)
    return false if statuses.empty?

    prev_id = Status.offset(statuses.offset - 1).pick(:id)
    status.move_after_anchor(prev_id, scope: Status.all)
  end

  def valid_drop_request?
    drop_params[:list_type] == Status::SORTABLE_LIST_TYPE &&
      params[:list_id].blank? &&
      (params[:list_id].nil? || drop_params.key?(:list_id)) &&
      drop_params.key?(:prev_id)
  end

  def drop_params
    @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
  end

  def recompute_progress_values
    attributes_triggering_recomputing = ["excluded_from_totals"]
    attributes_triggering_recomputing << "default_done_ratio" if WorkPackage.status_based_mode?
    changes = @status.previous_changes.slice(*attributes_triggering_recomputing)
    return if changes.empty?

    WorkPackages::Progress::ApplyStatusesChangeJob
      .perform_later(cause_type: "status_changed",
                     status_name: @status.name,
                     status_id: @status.id,
                     changes:)
  end
end
