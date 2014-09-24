#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::MovesController < ApplicationController
  default_search_scope :work_packages
  before_filter :find_work_packages, :check_project_uniqueness
  before_filter :authorize

  def new
    WorkPackageBulkUpdateService.new(@work_packages, @projects)
    .run(params).available_attributes.each do |key, value|
      self.instance_variable_set(:"@#{key}", value)
    end
    respond_to do |format|
      format.html
      format.js do
        type_id = params[:new_type_id].nil? ? params[:work_package][:type_id] : params[:new_type_id]
        wp_type = @target_project.types.find_by_id(type_id)
        @statuses = []
        @work_packages.each do |wp|
          wp_status = wp.status
          current_user_role = current_user.roles_for_project(@target_project)
          @statuses += wp_status.find_new_statuses_allowed_to(current_user_role, wp_type)
        end
        @statuses.uniq!
        render template: 'work_packages/moves/change_type', layout: false
      end
    end
  end

  def create
    WorkPackageBulkUpdateService.new(@work_packages, @projects)
    .save(params, true).each do |key, value|
      self.instance_variable_set(:"@#{key}", value)
    end

    set_flash_from_bulk_work_package_save(@work_packages, @unsaved_work_package_ids)

    if params[:follow]
      if @work_packages.size == 1 && @moved_work_packages.size == 1
        redirect_to work_package_path(@moved_work_packages.first)
      else
        redirect_to project_work_packages_path(@target_project || @project)
      end
    else
      redirect_to project_work_packages_path(@project)
    end
    return
  end

  def set_flash_from_bulk_work_package_save(work_packages, unsaved_work_package_ids)
    if unsaved_work_package_ids.empty? and not work_packages.empty?
      flash[:notice] = (@copy) ? l(:notice_successful_create) : l(:notice_successful_update)
    else
      flash[:error] = l(:notice_failed_to_save_work_packages,
                        :count => unsaved_work_package_ids.size,
                        :total => work_packages.size,
                        :ids => '#' + unsaved_work_package_ids.join(', #'))
    end
  end

  def default_breadcrumb
    l(:label_move_work_package)
  end
end
