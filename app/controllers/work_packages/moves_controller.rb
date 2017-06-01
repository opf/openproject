#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::MovesController < ApplicationController
  default_search_scope :work_packages
  before_action :find_work_packages, :check_project_uniqueness
  before_action :authorize

  def new
    prepare_for_work_package_move
  end

  def create
    prepare_for_work_package_move

    new_type = params[:new_type_id].blank? ? nil : @target_project.types.find_by(id: params[:new_type_id])
    unsaved_work_package_ids = []
    moved_work_packages = []
    @work_packages.each do |work_package|
      work_package.reload

      call_hook(:controller_work_packages_move_before_save,  params: params, work_package: work_package, target_project: @target_project, copy: !!@copy)

      permitted_params = params.permit(:copy,
                                       :assigned_to_id,
                                       :responsible_id,
                                       :start_date,
                                       :due_date,
                                       :status_id,
                                       :priority_id,
                                       :follow,
                                       :new_type_id,
                                       :new_project_id,
                                       ids: [])

      move_service = MoveWorkPackageService.new(work_package, current_user)
      if r = move_service.call(@target_project, new_type, copy: @copy,
                                                          attributes: permitted_params,
                                                          journal_note: @notes)
        moved_work_packages << r
      else
        unsaved_work_package_ids << work_package.id
      end
    end
    set_flash_from_bulk_work_package_save(@work_packages, unsaved_work_package_ids)

    if params[:follow]
      if @work_packages.size == 1 && moved_work_packages.size == 1
        redirect_to work_package_path(moved_work_packages.first)
      else
        redirect_to project_work_packages_path(@target_project || @project)
      end
    else
      redirect_back_or_default(project_work_packages_path(@project))
    end
  end

  def set_flash_from_bulk_work_package_save(work_packages, unsaved_work_package_ids)
    if unsaved_work_package_ids.empty? and not work_packages.empty?
      flash[:notice] = (@copy) ? l(:notice_successful_create) : l(:notice_successful_update)
    else
      flash[:error] = l(:notice_failed_to_save_work_packages,
                        count: unsaved_work_package_ids.size,
                        total: work_packages.size,
                        ids: '#' + unsaved_work_package_ids.join(', #'))
    end
  end

  def default_breadcrumb
    l(:label_move_work_package)
  end

  private

  # Check if project is unique before bulk operations
  def check_project_uniqueness
    unless @project
      # TODO: let users bulk move/copy work packages from different projects
      render_error I18n.t('work_packages.move.unsupported_for_multiple_projects')
      return false
    end
  end

  def prepare_for_work_package_move
    @work_packages = @work_packages.sort
    @copy = params.has_key? :copy
    @allowed_projects = WorkPackage.allowed_target_projects_on_move(current_user)
    @target_project = @allowed_projects.detect { |p| p.id.to_s == params[:new_project_id].to_s } if params[:new_project_id]
    @target_project ||= @project
    @types = @target_project.types
    @available_statuses = Workflow.available_statuses(@project)
    @notes = params[:notes]
    @notes ||= ''
  end
end
