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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::Settings::CreationWizardController < Projects::SettingsController
  include OpTurbo::ComponentStream

  menu_item :settings_creation_wizard

  before_action :check_enterprise_plan, only: :toggle
  before_action :check_activation_conditions, only: :toggle

  def show; end

  def disable_dialog
    respond_with_dialog Projects::Settings::CreationWizard::DisableDialogComponent.new(
      project: @project
    )
  end

  def toggle
    enabling = !@project.project_creation_wizard_enabled
    @project.update!(project_creation_wizard_enabled: enabling)

    # Enabling PIR will enable all the project's currently active
    # project attributes for PIR by default.
    # Note that project attributes that are added to the project *later*
    # are not enabled in PIR automatically.
    # They will have to be enabled explicitly on the attributes tab.
    enable_creation_wizard_for_all_mappings! if enabling

    redirect_to project_settings_creation_wizard_path(@project, tab: params[:tab]), status: :see_other
  end

  def update_name_settings
    update_settings_for_tab("name", name_settings_params)
  end

  def update_submission_settings
    update_settings_for_tab("submission", submission_settings_params)
  end

  def update_artifact_export_settings
    update_settings_for_tab("export", artifact_export_settings_params)
  end

  def refresh_submission_form
    @project.assign_attributes(submission_settings_params)

    update_via_turbo_stream(
      component: Projects::Settings::CreationWizard::SubmissionFormComponent.new(project: @project)
    )

    respond_with_turbo_streams
  end

  def toggle_project_custom_field
    cf = ProjectCustomField.find(permitted_params.project_custom_field_project_mapping[:custom_field_id])
    mapping = cf.project_custom_field_project_mappings.find_by(project: @project)

    if custom_field_toggleable?(cf) && toggle_mapping(mapping)
      render json: {}, status: :ok
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def enable_all_of_section
    update_section_mappings(true)
  end

  def disable_all_of_section
    update_section_mappings(false)
  end

  private

  def check_enterprise_plan
    # Allow disabling even without enterprise plan
    return if @project.project_creation_wizard_enabled

    unless EnterpriseToken.allows_to?(:project_creation_wizard)
      flash[:error] = I18n.t(:notice_requires_enterprise_token)
      redirect_to project_settings_creation_wizard_path(@project, tab: "attributes"), status: :see_other
    end
  end

  def check_activation_conditions
    # Allow disabling even without activation conditions met
    return if @project.project_creation_wizard_enabled

    error = if @project.project_creation_wizard_default_work_package_type.nil?
              I18n.t("projects.settings.creation_wizard.errors.no_work_package_type")
            elsif @project.project_creation_wizard_default_status_when_submitted.nil?
              type = @project.project_creation_wizard_default_work_package_type.name
              I18n.t("projects.settings.creation_wizard.errors.no_status_when_submitted", type:)
            end

    if error
      flash[:error] = error
      redirect_to project_settings_creation_wizard_path(@project, tab: params[:tab]), status: :see_other
    end
  end

  def update_section_mappings(value)
    section_id = permitted_params.project_custom_field_project_mapping[:custom_field_section_id]

    cf_ids_to_toggle, force_enabled_cf_ids = ProjectCustomField.toggleable_ids_in_creation_wizard_settings(@project, section_id)

    ProjectCustomFieldProjectMapping
      .where(project_id: @project.id, custom_field_id: cf_ids_to_toggle)
      .update_all(creation_wizard: value)

    enable_creation_wizard!(force_enabled_cf_ids)

    redirect_to project_settings_creation_wizard_path(@project, tab: "attributes"), status: :see_other
  end

  def enable_creation_wizard!(custom_field_ids)
    ProjectCustomFieldProjectMapping
      .where(project_id: @project.id, custom_field_id: custom_field_ids)
      .update_all(creation_wizard: true)
  end

  def enable_creation_wizard_for_all_mappings!
    @project.project_custom_field_project_mappings.update_all(creation_wizard: true)
  end

  def custom_field_toggleable?(custom_field)
    toggleable_ids = ProjectCustomField
                       .toggleable_ids_in_creation_wizard_settings(@project, custom_field.custom_field_section_id)
                       .first

    toggleable_ids.include?(custom_field.id)
  end

  def toggle_mapping(mapping)
    mapping&.update(creation_wizard: !mapping.creation_wizard)
  end

  def check_feature_flag
    unless OpenProject::FeatureDecisions.project_initiation_active?
      render_404
    end
  end

  def update_settings_for_tab(tab, settings_params)
    call = Projects::UpdateService
             .new(model: @project, user: current_user, contract_class: Projects::SettingsContract)
             .call(settings_params)

    @project = call.result

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_settings_creation_wizard_path(@project, tab:)
    else
      params[:tab] = tab
      render action: :show, status: :unprocessable_entity
    end
  end

  def name_settings_params
    params.expect(
      project: %i[project_creation_wizard_artifact_name]
    )
  end

  def submission_settings_params
    params.expect(
      project: %i[project_creation_wizard_work_package_type_id
                  project_creation_wizard_status_when_submitted_id
                  project_creation_wizard_send_confirmation_email
                  project_creation_wizard_notification_text
                  project_creation_wizard_assignee_custom_field_id
                  project_creation_wizard_work_package_comment]
    )
  end

  def artifact_export_settings_params
    params.expect(
      project: %i[project_creation_wizard_artifact_export_type
                  project_creation_wizard_artifact_export_storage]
    )
  end
end
