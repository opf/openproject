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

class Projects::CreationWizardController < ApplicationController
  include OpTurbo::ComponentStream

  load_and_authorize_with_permission_in_project :edit_project_attributes
  before_action :load_sections_and_fields, only: %i[show update]
  before_action :find_current_section, only: %i[show update]

  layout "no_menu"

  def show
    render locals: { menu_name: :none }
  end

  def help_text
    custom_field = ProjectCustomField.visible.find(params[:custom_field_id])
    replace_via_turbo_stream component: Projects::Wizard::HelpTextComponent.new(custom_field)
    respond_with_turbo_streams
  end

  def update
    service_call = Projects::UpdateService
      .new(user: current_user, model: @project, contract_options: { project_attributes_only: true })
      .call(permitted_params.project)

    if service_call.success?
      if last_page?
        create_work_package_artifact
      else
        redirect_to project_creation_wizard_path(@project, section: params[:next_section])
      end
    else
      @project = service_call.result
      render_wizard_error_step
    end
  end

  private

  def render_wizard_error_step
    render :show,
           locals: { menu_name: :none },
           status: :unprocessable_entity
  end

  def create_work_package_artifact # rubocop:disable Metrics/AbcSize
    creation_call = User.execute_as_admin(current_user) do
      Projects::CreationWizard::SubmitArtifactService
        .new(user: current_user, project: @project)
        .call
    end

    # even when successful, there can be errors related to the artifact
    # upload to Nextcloud that needs to be shown to the user
    if creation_call.success?
      flash[:error] = creation_call.errors.full_messages if creation_call.errors.any?
      redirect_to project_work_packages_path(@project, @project.project_creation_wizard_artifact_work_package_id),
                  notice: I18n.t("projects.wizard.success")
    else
      flash.now[:error] = creation_call.errors.full_messages
      render_wizard_error_step
    end
  end

  def last_page?
    params[:finish]
  end

  def load_sections_and_fields
    enabled_in_wizard_ids = @project
      .project_custom_field_project_mappings
      .where(creation_wizard: true)
      .select(:custom_field_id)

    scoped_fields = @project.available_custom_fields.where(id: enabled_in_wizard_ids)
    @custom_fields_by_section = ProjectCustomFieldSection.grouped_in_order(scoped_fields).to_h
  end

  def find_current_section
    section_id = params[:section]
    @current_section =
      if section_id.blank?
        @custom_fields_by_section.keys.first
      else
        @custom_fields_by_section.keys.find { |s| s.id.to_s == section_id.to_s } || @custom_fields_by_section.keys.first
      end
  end
end
