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

class VersionsController < ApplicationController
  menu_item :roadmap, only: %i(index show)
  menu_item :settings_versions

  model_object Version
  before_action :find_model_object, except: %i[index new create close_completed]
  before_action :find_project_from_association, except: %i[index new create close_completed]
  before_action :find_project, only: %i[index new create close_completed]
  before_action :authorize

  def index
    @types = @project.types.order(Arel.sql("position"))
    retrieve_selected_type_ids(@types, @types.select(&:is_in_roadmap?))
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_work_packages? : (params[:with_subprojects].to_i == 1)
    project_ids = @with_subprojects ? @project.self_and_descendants.includes(:wiki).map(&:id) : [@project.id]

    @versions = find_versions(@with_subprojects, params[:completed])

    @wps_by_version = {}
    unless @selected_type_ids.empty?
      @versions.each do |version|
        @wps_by_version[version] = work_packages_of_version(version, project_ids, @selected_type_ids)
      end
    end
    @versions.reject! { |version| !project_ids.include?(version.project_id) && @wps_by_version[version].blank? }
  end

  def show
    @issues = @version
      .work_packages
      .visible
      .includes(:status, :type, :priority)
      .order("#{::Type.table_name}.position, #{WorkPackage.table_name}.id")
  end

  def new
    @version = @project.versions.build
  end

  def edit; end

  def create
    attributes = permitted_params
      .version
      .merge(project_id: @project.id)

    call = Versions::CreateService
      .new(user: current_user)
      .call(attributes)

    render_cu(call, :notice_successful_create, "new")
  end

  def update
    attributes = permitted_params
      .version

    call = Versions::UpdateService
      .new(user: current_user,
           model: @version)
      .call(attributes)

    render_cu(call, :notice_successful_update, "edit")
  end

  def close_completed
    if request.put?
      @project.close_completed_versions
    end
    redirect_to project_settings_versions_path(@project)
  end

  def destroy
    call = Versions::DeleteService
      .new(user: current_user,
           model: @version)
      .call

    unless call.success?
      flash[:error] = call.errors.full_messages
      flash[:error] << archived_project_mesage if archived_projects.any?
    end

    redirect_to project_settings_versions_path(@project)
  end

  private

  def archived_project_mesage
    if current_user.admin?
      ApplicationController.helpers.sanitize(
        t(:error_can_not_delete_in_use_archived_work_packages,
          archived_projects_urls: helpers.archived_projects_urls_for(archived_projects)),
        attributes: %w(href target)
      )
    else
      t(:error_can_not_delete_in_use_archived_undisclosed)
    end
  end

  def archived_projects
    @archived_projects ||= @version.projects.archived
  end

  def redirect_back_or_version_settings
    redirect_back_or_default(project_settings_versions_path(@project))
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_selected_type_ids(selectable_types, default_types = nil)
    @selected_type_ids = selected_type_ids selectable_types, default_types
  end

  def selected_type_ids(selectable_types, default_types = nil)
    if (ids = params[:type_ids])
      ids.is_a?(Array) ? ids.map(&:to_s) : ids.split("/")
    else
      (default_types || selectable_types).map { |t| t.id.to_s }
    end
  end

  def render_cu(call, success_message, failure_action)
    @version = call.result

    if call.success?
      flash[:notice] = t(success_message)
      redirect_back_or_version_settings
    else
      render action: failure_action
    end
  end

  def find_versions(subprojects, completed)
    versions = @project.shared_versions.includes(:custom_values)

    if subprojects
      versions = versions.or(@project.rolled_up_versions.includes(:custom_values))
    end

    versions = versions.visible.order_by_semver_name.except(:distinct).uniq
    versions.reject! { |version| version.closed? || version.completed? } unless completed
    versions
  end

  def work_packages_of_version(version, project_ids, selected_type_ids)
    version
      .work_packages
      .visible
      .includes(:project, :status, :type, :priority)
      .where(type_id: selected_type_ids, project_id: project_ids)
      .order("#{Project.table_name}.lft, #{::Type.table_name}.position, #{WorkPackage.table_name}.id")
  end
end
