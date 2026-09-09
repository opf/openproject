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

class Projects::Settings::WorkPackages::TypesController < Projects::SettingsController
  include WorkPackageTypes::TypeDeactivationErrorMessage
  include WorkPackageTypes::TypeVariantsFeature
  include OpTurbo::ComponentStream
  include FlashMessagesOutputSafetyHelper

  menu_item :settings_work_packages

  before_action :require_type_variants_feature, only: %i[new create destroy]

  def index
    @types = ::Type.all
  end

  def new
    respond_with_dialog Projects::Settings::WorkPackages::Types::AddDialogComponent.new(project: @project)
  end

  def create # rubocop:disable Metrics/AbcSize
    variant = ::TypeVariant.find_by(id: params[:variant_id])

    return render_type_not_found if variant.nil?

    result = ::Projects::Types::AddService.new(user: current_user, model: @project).call(variant:)

    result.on_success do
      close_dialog_via_turbo_stream(Projects::Settings::WorkPackages::Types::AddDialogComponent::DIALOG_ID)
      replace_types_list
    end

    result.on_failure do
      render_error_flash_message_via_turbo_stream(message: join_flash_messages(result.errors.full_messages))
    end

    respond_to_with_turbo_streams(status: result)
  end

  def destroy # rubocop:disable Metrics/AbcSize
    type = ::Type.find_by(id: params[:id])

    return render_type_not_found if type.nil? || !@project.project_types.exists?(type_id: type.id)

    variant = @project.type_variant(type)

    result = ::Projects::Types::RemoveService.new(user: current_user, model: @project).call(variant:)

    result.on_success { replace_types_list }

    result.on_failure do
      render_error_flash_message_via_turbo_stream(
        message: join_flash_messages(
          type_deactivation_error_messages(variant, project_ids: [@project.id])
        )
      )
    end

    respond_to_with_turbo_streams(status: result)
  end

  def bulk_update
    type_ids = permitted_params.projects_type_ids

    if UpdateProjectsTypesService.new(@project).call(type_ids)
      flash[:notice] = success_message
    else
      flash[:error] = type_deactivation_error_messages(variants_missing_from(type_ids), project_ids: [@project.id])
    end

    redirect_to project_settings_types_path(@project.identifier)
  end

  private

  # Reload so the repainted list no longer sees the association's cached types.
  def replace_types_list
    replace_via_turbo_stream(
      component: Projects::Settings::WorkPackages::Types::ListComponent.new(project: @project.reload)
    )
  end

  def render_type_not_found
    render_error_flash_message_via_turbo_stream(message: t("projects.settings.types.type_not_found"))

    respond_to_with_turbo_streams(status: :unprocessable_entity)
  end

  def success_message
    ApplicationController.helpers.sanitize(
      t(:notice_successful_update_custom_fields_added_to_project, url: project_settings_custom_fields_path(@project)),
      attributes: %w(href target)
    )
  end

  def variants_missing_from(type_ids)
    @project
      .types_used_by_work_packages
      .where.not(id: type_ids.presence)
      .map { |type| @project.type_variant(type) }
  end
end
