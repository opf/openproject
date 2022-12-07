#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  include WorkPackages::FlashBulkError

  default_search_scope :work_packages
  before_action :find_work_packages, :check_project_uniqueness
  before_action :authorize

  def new
    prepare_for_work_package_move
  end

  def create
    prepare_for_work_package_move

    result = modify_call

    set_flash_from_bulk_work_package_save(@work_packages, result)

    redirect_after_create(result)
  end

  private

  def modify_call
    klass = if @copy
              WorkPackages::Bulk::CopyService
            else
              WorkPackages::Bulk::MoveService
            end

    klass
      .new(user: current_user, work_packages: @work_packages)
      .call(attributes_for_create)
  end

  def redirect_after_create(result)
    if params[:follow]
      if result.success? && @work_packages.size == 1
        redirect_to work_package_path(result.dependent_results.first.result)
      else
        redirect_to project_work_packages_path(@target_project || @project)
      end
    else
      redirect_back_or_default(project_work_packages_path(@project))
    end
  end

  def set_flash_from_bulk_work_package_save(work_packages, service_result)
    if service_result.success? && work_packages.any?
      flash[:notice] = @copy ? I18n.t(:notice_successful_create) : I18n.t(:notice_successful_update)
    else
      error_flash(work_packages,
                  service_result)
    end
  end

  def default_breadcrumb
    I18n.t(:label_move_work_package)
  end

  # Check if project is unique before bulk operations
  def check_project_uniqueness
    unless @project
      # TODO: let users bulk move/copy work packages from different projects
      render_error message: :'work_packages.move.unsupported_for_multiple_projects', status: 400
      false
    end
  end

  def prepare_for_work_package_move
    @copy = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move(current_user)
    @target_project = @allowed_projects.detect { |p| p.id.to_s == params[:new_project_id].to_s } if params[:new_project_id]
    @target_project ||= @project
    @types = @target_project.types
    @target_type = @types.find { |t| t.id.to_s == params[:new_type_id].to_s }
    @available_versions = @target_project.assignable_versions
    @available_statuses = Workflow.available_statuses(@project)
    @notes = params[:notes] || ''
  end

  def attributes_for_create
    permitted_params
      .move_work_package
      .compact_blank
      # 'none' is used in the frontend as a value to unset the property, e.g. the assignee.
      .transform_values { |v| v == 'none' ? nil : v }
      .to_h
  end
end
