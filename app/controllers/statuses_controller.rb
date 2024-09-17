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

class StatusesController < ApplicationController
  include PaginationHelper

  layout "admin"

  before_action :require_admin

  def index
    @statuses = Status.page(page_param)
                .per_page(per_page_param)

    render action: "index", layout: false if request.xhr?
  end

  def new
    @status = Status.new
  end

  def edit
    @status = Status.find(params[:id])
  end

  def create
    @status = Status.new(permitted_params.status)
    if @status.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to action: "index"
    else
      render action: "new"
    end
  end

  def update
    @status = Status.find(params[:id])
    if @status.update(permitted_params.status)
      recompute_progress_values
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to action: "index"
    else
      render action: "edit"
    end
  end

  def destroy
    status = Status.find(params[:id])
    if status.is_default?
      flash[:error] = I18n.t(:error_unable_delete_default_status)
    else
      status.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
    end
    redirect_to action: "index"
  rescue StandardError
    flash[:error] = I18n.t(:error_unable_delete_status)
    redirect_to action: "index"
  end

  protected

  def show_local_breadcrumb
    false
  end

  def recompute_progress_values
    attributes_triggering_recomputing = ["excluded_from_totals"]
    attributes_triggering_recomputing << "default_done_ratio" if WorkPackage.use_status_for_done_ratio?
    changes = @status.previous_changes.slice(*attributes_triggering_recomputing)
    return if changes.empty?

    WorkPackages::Progress::ApplyStatusesChangeJob
      .perform_later(cause_type: "status_changed",
                     status_name: @status.name,
                     status_id: @status.id,
                     changes:)
  end
end
