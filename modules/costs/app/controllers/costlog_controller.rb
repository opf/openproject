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

class CostlogController < ApplicationController
  menu_item :work_packages
  before_action :find_cost_entry_work_package_or_project, :authorize, only: %i[edit new create update destroy]

  helper :work_packages
  include CostlogHelper

  def new
    unless @project&.cost_types_available?
      flash[:error] = I18n.t("cost_types.errors.no_cost_types_available") # rubocop:disable Rails/ActionControllerFlashBeforeRender
      redirect_back_or_default(@work_package ? polymorphic_path(@work_package) : project_path(@project))
      return
    end

    new_default_cost_entry

    render action: "edit"
  end

  def edit
    render_403 unless @cost_entry.try(:editable_by?, User.current)
  end

  def create
    service_call = CostEntries::CreateService
                     .new(user: current_user, model: CostEntry.new(project: @project))
                     .call(permitted_params.cost_entry)

    respond_with_service_call(service_call) do |call|
      @cost_entry = call.result

      if call.success?
        flash[:notice] = t(:notice_cost_logged_successfully)
        redirect_back_or_default polymorphic_path(@cost_entry.entity)
      else
        render action: :edit, status: :unprocessable_entity
      end
    end
  end

  def update
    service_call = CostEntries::UpdateService
                     .new(user: current_user, model: @cost_entry)
                     .call(permitted_params.cost_entry)

    respond_with_service_call(service_call) do |call|
      @cost_entry = call.result

      if call.success?
        flash[:notice] = t(:notice_successful_update)
        redirect_back_or_to(polymorphic_path(@cost_entry.entity))
      else
        render action: "edit"
      end
    end
  end

  def destroy
    render_404 and return unless @cost_entry

    service_call = CostEntries::DeleteService.new(user: current_user, model: @cost_entry).call

    respond_with_service_call(service_call) do
      flash[:notice] = t(:notice_successful_delete)

      if request.referer.include?("cost_reports")
        redirect_to controller: "/cost_reports", action: :index, status: :see_other
      else
        redirect_back_or_to(polymorphic_path(@cost_entry.entity), status: :see_other)
      end
    end
  end

  private

  def find_cost_entry_work_package_or_project # rubocop:disable Metrics/AbcSize
    if params[:id]
      @cost_entry = CostEntry.visible.find(params[:id])
      @project = @cost_entry.project
    elsif params[:work_package_id]
      @work_package = WorkPackage.visible.find(params[:work_package_id])
      @project = @work_package.project
    elsif params[:project_id]
      @project = Project.visible.find(params[:project_id])
    else
      render_404
    end
  end

  # Renders 403 when the service call failed because of missing permissions and
  # yields the call otherwise, so each action handles its own success and
  # validation outcomes consistently.
  def respond_with_service_call(service_call)
    if service_unauthorized?(service_call)
      render_403
    else
      yield service_call
    end
  end

  def service_unauthorized?(service_call)
    service_call.errors.added?(:base, :error_unauthorized)
  end

  def new_default_cost_entry
    @cost_entry = CostEntry.new.tap do |ce|
      ce.project = @project
      ce.entity = @work_package
      ce.user = User.current
      ce.spent_on = Time.zone.today
      ce.cost_type = CostType.default_for_project(@project) if @project
    end
  end
end
