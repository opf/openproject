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

  before_action :find_project, except: %i[index new export_list_modal]
  before_action :load_query_or_deny_access, only: %i[index export_list_modal]
  before_action :authorize, only: %i[copy deactivate_work_package_attachments]
  before_action :authorize_global, only: %i[new]
  before_action :require_admin, only: %i[destroy destroy_info]

  no_authorization_required! :index, :export_list_modal

  include SortHelper
  include PaginationHelper
  include QueriesHelper
  include ProjectsHelper
  include Projects::QueryLoading
  include OpTurbo::DialogStreamHelper

  helper_method :has_managed_project_folders?

  current_menu_item :index do
    :projects
  end

  def index # rubocop:disable Format/AbcSize
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

        current_url = url_for(params.permit(:conroller, :action, :query_id, :filters, :columns, :sortBy, :page, :per_page))
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
    render layout: "no_menu"
  end

  def copy
    render
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

    redirect_to projects_path
  end

  def destroy_info
    @project_to_destroy = @project

    hide_project_in_layout
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

  def export_list_modal
    respond_with_dialog Projects::ExportListModalComponent.new(query: @query)
  end

  private

  def has_managed_project_folders?(project)
    project.project_storages.any?(&:project_folder_automatic?)
  end

  def hide_project_in_layout
    @project = nil
  end

  def export_list(query, mime_type)
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

  def supported_export_formats
    ::Exports::Register.list_formats(Project).map(&:to_s)
  end

  helper_method :supported_export_formats
end
