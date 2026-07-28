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

# All actions either update the workflow matrix editor's internal representation or render dialogs to ensure
# that the editor can be modified regardless of the context it is used in
class Workflows::MatrixController < ApplicationController
  include OpTurbo::ComponentStream

  layout false

  before_action :require_admin

  helper_method :matrix_context

  def show
    unless turbo_frame_request?
      redirect_to edit_type_workflow_path(type, role_ids: params[:role_ids], tab: matrix_context.tab)
    end
  end

  def update
    if persist_matrix.success?
      render_matrix_saved
    else
      render_matrix_not_saved
    end

    respond_with_turbo_streams
  end

  def status_dialog
    respond_with_dialog Workflows::StatusDialogComponent.new(
      all_statuses: Status.order(:position),
      current_statuses: dialog_statuses,
      roles: matrix_context.roles,
      type:,
      tab: matrix_context.tab
    )
  end

  def confirm_statuses
    if removed_status_count.positive?
      respond_with_dialog Workflows::StatusRemovalDangerDialogComponent.new(
        roles: matrix_context.roles,
        type:,
        tab: matrix_context.tab,
        status_ids: requested_status_ids,
        removed_count: removed_status_count
      )
    else
      update_via_turbo_stream(component: matrix_editor_component)
      respond_with_turbo_streams
    end
  end

  private

  def type
    @type ||= ::Type.find(params.expect(:type_id))
  end

  def matrix_context
    @matrix_context ||= build_matrix_context
  end

  def build_matrix_context
    Workflows::MatrixContext.new(
      type:,
      tab: params[:tab],
      role_ids: params[:role_ids],
      status_ids: params[:status_ids]
    )
  end

  def matrix_editor_component(context = matrix_context)
    Workflows::MatrixEditorComponent.new(context:)
  end

  def persist_matrix
    Workflows::MatrixUpdateService
      .new(type:, roles: matrix_context.roles, tab: matrix_context.tab)
      .call(status: params[:status], indeterminate_status: params[:indeterminate_status])
  end

  def render_matrix_saved
    render_flash_message_via_turbo_stream(
      message: I18n.t(:notice_successful_update),
      scheme: :success
    )

    # Resolved afresh: the write just changed which statuses have transitions, and with
    # none left the matrix has to give way to the blankslate.
    saved = build_matrix_context
    update_via_turbo_stream(component: matrix_editor_component(saved)) if saved.statuses.empty?
  end

  def render_matrix_not_saved
    render_flash_message_via_turbo_stream(
      message: I18n.t(:notice_unsuccessful_update),
      scheme: :danger
    )
    @turbo_status = :unprocessable_entity
  end

  def requested_status_ids
    @requested_status_ids ||= Array(params[:status_ids]).flatten.map(&:to_i)
  end

  def removed_status_count
    original_ids = Array(params[:original_status_ids]).flatten.map(&:to_i)

    (original_ids - requested_status_ids).size
  end

  # The dialog opens on the pending selection when there is one, otherwise on what the
  # selected roles have saved — and on nothing at all while no role is selected.
  def dialog_statuses
    return Status.none if requested_status_ids.blank? && matrix_context.roles.empty?

    matrix_context.statuses
  end
end
