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

class Workflows::Copies::FromRolesController < ApplicationController
  include WorkPackageTypes::AddressesVariant
  include ::WorkPackageTypes::ConfiguredInScope
  include OpTurbo::ComponentStream

  before_action :set_source_variant
  before_action :set_source_role
  before_action :set_target_roles

  def create # rubocop:disable Metrics/AbcSize
    if @source_variant.nil? || @source_role.nil?
      render_flash_message_via_turbo_stream(
        message: I18n.t(:error_workflow_copy_source),
        scheme: :danger
      )
      @turbo_status = :unprocessable_entity
    elsif @target_roles.blank?
      render_flash_message_via_turbo_stream(
        message: I18n.t(:error_workflow_copy_target),
        scheme: :danger
      )
      @turbo_status = :unprocessable_entity
    else
      Workflow.copy(@source_variant, @source_role, [@source_variant], @target_roles)

      close_dialog_via_turbo_stream("copy_from_type_dialog")
      render_success_flash_message_via_turbo_stream(
        message: t(".notice", count: @target_roles.size, role_name: @target_roles.first.name)
      )
      set_frame_src_via_turbo_stream(
        "workflow-table",
        type_workflow_matrix_path(**@source_variant.path_args,
                                  tab: params[:tab], role_ids: @target_roles.map(&:id))
      )
    end

    respond_with_turbo_streams
  end

  private

  # A stale dialog can name a source that is gone; #create answers that with a flash rather
  # than a 404, so a miss has to arrive here as nil.
  def set_source_variant
    @source_variant = addressed_variant
  rescue ActiveRecord::RecordNotFound
    @source_variant = nil
  end

  def set_source_role
    @source_role = eligible_roles.find_by(id: params[:source_role_id])
  end

  def set_target_roles
    @target_roles = eligible_roles.where(id: params[:target_role_ids])
  end

  def eligible_roles
    @eligible_roles ||= Workflow.eligible_roles
  end
end
