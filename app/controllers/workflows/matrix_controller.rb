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
  include WorkPackageTypes::AddressesVariant
  include ::WorkPackageTypes::ConfiguredInScope
  include OpTurbo::ComponentStream

  layout false

  helper_method :matrix_context

  def show
    unless turbo_frame_request?
      redirect_to edit_type_workflow_path(**variant.path_args,
                                          role_ids: params[:role_ids], tab: matrix_context.tab)
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
    respond_with_dialog Workflows::StatusDialogComponent.new(context: matrix_context)
  end

  def confirm_statuses
    if matrix_context.removed_displayed_status_ids.any?
      respond_with_dialog Workflows::StatusRemovalDangerDialogComponent.new(context: matrix_context)
    else
      update_via_turbo_stream(component: matrix_editor_component)
      respond_with_turbo_streams
    end
  end

  private

  def variant
    @variant ||= addressed_variant
  end

  def matrix_context
    @matrix_context ||= build_matrix_context
  end

  def build_matrix_context
    Workflows::MatrixContext.new(
      variant:,
      tab: params[:tab],
      role_ids: params[:role_ids],
      status_ids: params[:status_ids],
      displayed_status_ids: params[:displayed_status_ids]
    )
  end

  def matrix_editor_component(context = matrix_context)
    Workflows::MatrixEditorComponent.new(context:)
  end

  def persist_matrix
    Workflows::MatrixUpdateService
      .new(variant:, roles: matrix_context.roles, tab: matrix_context.tab)
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
end
