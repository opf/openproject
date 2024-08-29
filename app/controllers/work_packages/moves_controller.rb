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

class WorkPackages::MovesController < ApplicationController
  include WorkPackages::BulkErrorMessage

  default_search_scope :work_packages
  before_action :find_work_packages, :check_project_uniqueness
  before_action :authorize

  def new
    prepare_for_work_package_move
  end

  def create
    prepare_for_work_package_move

    perform_operation
  end

  private

  def perform_operation
    if within_frontend_treshold?
      perform_in_frontend
    else
      perform_in_background
    end
  end

  def within_frontend_treshold?
    WorkPackageHierarchy.where(ancestor_id: @work_packages).count <= Setting.work_packages_bulk_request_limit
  end

  # rubocop:disable Metrics/AbcSize
  def perform_in_frontend
    call = job_class
             .perform_now(**job_args)

    if call.success? && @work_packages.any?
      flash[:notice] = call.message
      redirect_to call.result
    else
      flash[:error] = bulk_error_message(@work_packages, call.dependent_results.first)
      redirect_back_or_default(project_work_packages_path(@project))
    end
  end

  # rubocop:enable Metrics/AbcSize

  def perform_in_background
    job = job_class.perform_later(**job_args)
    redirect_to job_status_path(job.job_id)
  end

  def job_args
    {
      user: current_user,
      work_package_ids: @work_packages.pluck(:id),
      project: @project,
      target_project: @target_project,
      params: attributes_for_create,
      follow: params[:follow]
    }
  end

  def job_class
    if @copy
      WorkPackages::BulkCopyJob
    else
      WorkPackages::BulkMoveJob
    end
  end

  def default_breadcrumb
    I18n.t(:label_move_work_package)
  end

  # Check if project is unique before bulk operations
  def check_project_uniqueness
    unless @project
      # TODO: let users bulk move/copy work packages from different projects
      render_error message: :"work_packages.move.unsupported_for_multiple_projects", status: 400
      false
    end
  end

  def prepare_for_work_package_move
    @copy = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move(current_user)
    @target_project = @allowed_projects.detect { |p| p.id.to_s == params[:new_project_id].to_s } if params[:new_project_id]
    @target_project ||= @project
    @types = @target_project.types.order(:position)
    @target_type = @types.find { |t| t.id.to_s == params[:new_type_id].to_s }
    @unavailable_type_in_target_project = set_unavailable_type_in_target_project
    @available_versions = @target_project.assignable_versions
    @available_statuses = Workflow.available_statuses(@project)
    @notes = params[:notes] || ""
  end

  def set_unavailable_type_in_target_project
    if @target_project == @project
      false
    elsif @target_type.nil?
      hierarchies = WorkPackageHierarchy
                      .includes(:ancestor)
                      .where(ancestor_id: @work_packages.select(:id))
      Type.where(id: hierarchies.map { _1.ancestor.type_id })
          .select("distinct id")
          .pluck(:id)
          .difference(@types.pluck(:id))
          .any?
    else
      @types.exclude?(@target_type)
    end
  end

  def attributes_for_create
    permitted_params
      .move_work_package
      .compact_blank
      # 'none' is used in the frontend as a value to unset the property, e.g. the assignee.
      .transform_values { |v| v == "none" ? nil : v }
      .to_h
  end
end
