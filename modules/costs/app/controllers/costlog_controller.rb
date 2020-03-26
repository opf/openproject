#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CostlogController < ApplicationController
  menu_item :work_packages
  before_action :find_project, :authorize, only: %i[edit new create update destroy]
  before_action :find_associated_objects, only: %i[create update]
  before_action :find_optional_project, only: %i[report]

  helper :work_packages
  include CostlogHelper

  def new
    new_default_cost_entry

    render action: 'edit'
  end

  def edit
    render_403 unless @cost_entry.try(:editable_by?, User.current)
  end

  def create
    new_default_cost_entry
    update_cost_entry_from_params

    if !@cost_entry.creatable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_cost_logged_successfully)
      redirect_back_or_default work_package_path(@cost_entry.work_package)
    else
      render action: 'edit'
    end
  end

  def update
    update_cost_entry_from_params

    if !@cost_entry.editable_by?(User.current)

      render_403

    elsif @cost_entry.save

      flash[:notice] = t(:notice_successful_update)
      redirect_back fallback_location: work_package_path(@cost_entry.work_package)

    else
      render action: 'edit'
    end
  end

  def destroy
    render_404 and return unless @cost_entry
    render_403 and return unless @cost_entry.editable_by?(User.current)
    @cost_entry.destroy
    flash[:notice] = t(:notice_successful_delete)

    if request.referer =~ /cost_reports/
      redirect_to controller: '/cost_reports', action: :index
    else
      redirect_back fallback_location: work_package_path(@cost_entry.work_package)
    end
  end

  def get_cost_type_unit_plural
    @cost_type = CostType.find(params[:cost_type_id]) unless params[:cost_type_id].empty?

    if request.xhr?
      render partial: 'cost_type_unit_plural', layout: false
    end
  end

  private

  def find_project
    # copied from timelog_controller.rb
    if params[:id]
      @cost_entry = CostEntry.find(params[:id])
      @project = @cost_entry.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:project_id]
      @project = Project.find(params[:project_id])
    else
      render_404
      return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    if !params[:work_package_id].blank?
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif !params[:work_package_id].blank?
      @work_package = WorkPackage.find(params[:work_package_id])
      @project = @work_package.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
    end

    if !params[:cost_type_id].blank?
      @cost_type = CostType.find(params[:cost_type_id])
    end
  end

  def find_associated_objects
    user_id = cost_entry_params.delete(:user_id)
    @user = @cost_entry.present? && @cost_entry.user_id == user_id ?
              @cost_entry.user :
              User.find_by_id(user_id)

    work_package_id = cost_entry_params.delete(:work_package_id)
    @work_package = @cost_entry.present? && @cost_entry.work_package_id == work_package_id ?
               @cost_entry.work_package :
               WorkPackage.find_by_id(work_package_id)

    cost_type_id = cost_entry_params.delete(:cost_type_id)
    @cost_type = @cost_entry.present? && @cost_entry.cost_type_id == cost_type_id ?
                   @cost_entry.cost_type :
                   CostType.find_by_id(cost_type_id)
  end

  def new_default_cost_entry
    @cost_entry = CostEntry.new.tap do |ce|
      ce.project  = @project
      ce.work_package = @work_package
      ce.user = User.current
      ce.spent_on = Date.today
      # notice that cost_type is set to default cost_type in the model
    end
  end

  def update_cost_entry_from_params
    @cost_entry.user = @user
    @cost_entry.work_package = @work_package
    @cost_entry.cost_type = @cost_type

    @cost_entry.attributes = permitted_params.cost_entry
  end

  private

  def cost_entry_params
    params.require(:cost_entry).permit(:work_package_id, :spent_on, :user_id,
                                       :cost_type_id, :units, :comments)
  end
end
