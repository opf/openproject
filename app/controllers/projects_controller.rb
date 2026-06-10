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

class ProjectsController < ApplicationController
  include OpTurbo::ComponentStream

  menu_item :overview
  menu_item :roadmap, only: :roadmap

  before_action :find_project, except: %i[index new create destroy destroy_info]
  before_action :find_project_including_archived, only: %i[destroy destroy_info]
  before_action :load_query_or_deny_access, only: %i[index]
  before_action :authorize,
                only: %i[copy_form copy deactivate_work_package_attachments export_project_initiation_pdf]
  before_action :authorize_global, only: %i[new create]
  before_action :require_admin, only: %i[destroy destroy_info]
  before_action :find_optional_parent, only: :new
  before_action :find_optional_template, only: %i[new create]

  no_authorization_required! :index

  include SortHelper
  include PaginationHelper
  include QueriesHelper
  include ProjectsHelper
  include Queries::Loading

  current_menu_item :index do
    :projects
  end

  current_menu_item :copy_form do
    :settings_general
  end

  def index # rubocop:disable Metrics/AbcSize
    respond_to do |format|
      format.html do
        flash.now[:error] = @query.errors.full_messages if @query.errors.any?

        render layout: "global", locals: { query: @query, state: :show }
      end

      format.any(*supported_export_formats) do
        export_list(@query, request.format.symbol)
      end

      format.turbo_stream do
        replace_via_turbo_stream(
          component: Projects::IndexPageHeaderComponent.new(query: @query, current_user:, state: :show, params:)
        )
        update_via_turbo_stream(
          component: Filter::FilterButtonComponent.new(query: @query, disable_buttons: false)
        )
        replace_via_turbo_stream(component: Projects::TableComponent.new(query: @query, current_user:, params:))

        current_url = url_for(params.permit(:controller, :action, :query_id, :filters, :columns, :sortBy, :page, :per_page))
        turbo_streams << turbo_stream.push_state(current_url)
        turbo_streams << turbo_stream.turbo_frame_set_src(
          "projects_sidemenu",
          projects_menu_url(query_id: @query.id, controller_path: "projects")
        )

        turbo_streams << turbo_stream.replace("flash-messages", helpers.render_flash_messages)

        render turbo_stream: turbo_streams
      end
    end
  end

  def new
    if from_template?
      new_from_template
    else
      new_blank
    end
  end

  def create
    if from_template?
      create_from_template
    else
      create_blank
    end
  end

  def copy_form
    @copy_options = Projects::CopyOptions.new
    @target_project = Projects::CopyService
      .new(user: current_user, source: @project, contract_options: { validate_model: false })
      .call(target_project_params: {}, attributes_only: true)
      .result

    render
  end

  def copy # rubocop:disable Metrics/AbcSize
    @copy_options = Projects::CopyOptions.new(permitted_params.copy_project_options)

    service_call = Projects::EnqueueCopyService
      .new(user: current_user, model: @project)
      .call(
        target_project_params: permitted_params.new_project.to_h,
        only: @copy_options.dependencies,
        send_notifications: @copy_options.send_notifications
      )

    if service_call.success?
      job = service_call.result
      redirect_to job_status_path(job.job_id)
    else
      @target_project = service_call.result
      flash.now[:error] = I18n.t(:notice_unsuccessful_create_with_reason, reason: service_call.message)
      render action: :copy_form, status: :unprocessable_entity
    end
  end

  # Delete @project
  def destroy
    service_call = ::Projects::ScheduleDeletionService
                    .new(user: current_user, model: @project)
                    .call

    if service_call.success?
      flash[:notice] = I18n.t("projects.delete.scheduled")
    else
      flash[:error] = I18n.t("projects.delete.schedule_failed", errors: service_call.errors.full_messages.join("\n"))
    end

    redirect_to projects_path, status: :see_other
  end

  def destroy_info
    respond_with_dialog Projects::DeleteDialogComponent.new(project: @project)
  end

  def deactivate_work_package_attachments
    call = Projects::UpdateService
             .new(user: current_user, model: @project, contract_class: Projects::SettingsContract)
             .call(deactivate_work_package_attachments: params[:value] != "1")

    if call.failure?
      render json: call.errors.full_messages.join(" "), status: :unprocessable_entity
    else
      head :no_content
    end
  end

  def export_project_initiation_pdf
    export = Project::PDFExport::ProjectInitiation.new(@project).export!
    send_data(export.content, type: export.mime_type, filename: export.title)
  rescue ::Exports::ExportError => e
    redirect_to project_path(@project), flash: { error: e.message }
  end

  private

  def find_project_including_archived
    # The actions that use this method are only accessible to admins, so we can show them archived projects as well and
    # can skip the visible scope here.
    @project = Project.find(params[:id])
  end

  def from_template? = @template.present?

  def new_blank
    params[:step] = params.fetch(:step, 1).to_i
    @new_project = @parent&.children&.build(params.permit(:workspace_type)) || Project.new(params.permit(:workspace_type))

    render layout: layout_for_new
  end

  def new_from_template
    params[:step] = 2
    @new_project = Projects::CopyService
      .new(user: current_user, source: @template, contract_options: { validate_model: false })
      .call(target_project_params: params.permit(:parent_id).to_h, attributes_only: true)
      .result

    render layout: layout_for_new
  end

  def create_blank # rubocop:disable Metrics/AbcSize
    service_call = Projects::CreateService
      .new(user: current_user)
      .call(permitted_params.new_project)

    @new_project = service_call.result

    if service_call.success?
      redirect_to project_path(@new_project), notice: I18n.t(:notice_successful_create)
    else
      # Do not display custom field errors if the form is submitted from the second page.
      clear_custom_field_errors!(@new_project) unless from_step_3?
      set_wizard_step!(@new_project)

      if service_call.message.present?
        flash.now[:error] = I18n.t(:notice_unsuccessful_create_with_reason, reason: service_call.message)
      end
      render action: :new, status: :unprocessable_entity, layout: "no_menu"
    end
  end

  def create_from_template # rubocop:disable Metrics/AbcSize
    @copy_options = Projects::CopyOptions.new

    target_project_params = permitted_params.new_project.to_h.merge(template: @template)

    service_call = Projects::EnqueueCopyService
      .new(user: current_user, model: @template)
      .call(
        target_project_params:,
        only: @copy_options.dependencies,
        skip_custom_field_validation: true,
        send_notifications: @copy_options.send_notifications
      )

    if service_call.success?
      job = service_call.result
      redirect_to job_status_path(job.job_id)
    else
      @new_project = service_call.result
      params[:step] = 2
      flash.now[:error] = I18n.t(:notice_unsuccessful_create_with_reason, reason: service_call.message)
      render action: :new, status: :unprocessable_entity, layout: "no_menu"
    end
  end

  def set_wizard_step!(project)
    attributes_with_error = project.errors.attribute_names
    second_step_attributes = %i[name description identifier parent]
    step_2_is_valid = !attributes_with_error.intersect?(second_step_attributes)

    params[:step] = step_2_is_valid ? 3 : 2
  end

  def clear_custom_field_errors!(project)
    # Delete custom field errors from project
    project.errors.attribute_names
      .select { |key| key.to_s.start_with?("custom_field") }
      .each { |key| project.errors.delete(key) }

    # Clear errors on custom value objects
    project.custom_values.each { |cv| cv.errors.clear }
  end

  def from_step_3?
    params[:step].to_i == 3
  end

  def find_optional_template
    template_id = find_template_id
    return if params[:workspace_type].blank? || template_id.blank?

    @template = Project
      .templated
      .workspace_type(params[:workspace_type])
      .visible(current_user)
      .find_by(id: template_id)
  end

  # Parent projects MAY define templates for subitems to be used
  # so if we have a parent, we want to search for one of these
  # if not, we return to the usual workflow
  def find_template_id
    return params[:template_id] if params[:template_id].present?

    if @parent && params[:workspace_type].present?
      @parent.subproject_template_assignments.find_by(workspace_type: params[:workspace_type])&.template_id
    end
  end

  def find_optional_parent
    @parent = Project.visible(current_user).find(params[:parent_id]) if params[:parent_id].present?
  end

  def export_list(query, mime_type)
    return not_authorized_on_export_list unless current_user.allowed_in_any_project?(:export_projects)

    job = Projects::ExportJob.perform_later(
      export: Projects::Export.create,
      user: current_user,
      mime_type:,
      query: query.to_hash
    )

    if request.headers["Accept"]&.include?("application/json")
      render json: { job_id: job.job_id }
    else
      redirect_to job_status_path(job.job_id)
    end
  end

  def not_authorized_on_export_list
    if request.headers["Accept"]&.include?("application/json")
      render json: { error: I18n.t(:notice_not_authorized) }, status: :forbidden
    else
      redirect_to projects_path, alert: I18n.t(:notice_not_authorized), status: :see_other
    end
  end

  def supported_export_formats
    ::Exports::Register.list_formats(Project).map(&:to_s)
  end

  def layout_for_new
    if portfolio_management_feature_missing?
      "global"
    else
      "no_menu"
    end
  end

  def login_back_url_params
    params.permit(:parent_id, :template_id, :step, :next_section)
  end
end
