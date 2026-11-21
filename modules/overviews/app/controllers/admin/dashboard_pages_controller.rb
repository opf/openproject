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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Admin::DashboardPagesController < ApplicationController
  include PaginationHelper

  layout "admin"
  menu_item :standard_dashboards

  before_action :authorize_global
  before_action :find_dashboard, except: %i[index new create]

  def index
    @dashboards = ::Grids::DashboardPage.central.includes(:dashboard_page_assignments).order(:name, :id)
    if params[:name].present?
      @dashboards = @dashboards.where("grids.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:name].to_s)}%")
    end
  end

  def new
    @dashboard = ::Grids::DashboardPage.new
    render :edit
  end

  def edit; end

  def create
    @dashboard = ::Grids::DashboardPage.new(row_count: 1, column_count: 1)
    save_dashboard
  end

  def update
    save_dashboard
  end

  def projects
    assigned_projects = Project.where(id: @dashboard.dashboard_page_assignments.select(:project_id))
    @projects = assigned_projects.order(:name, :id).paginate(page: page_param, per_page: per_page_param)
    @candidate_projects = Project.active.where.not(id: assigned_projects.select(:id))
  end

  def add_projects
    ids = Projects::AddAssignmentsForm.selected_ids(params.permit(project_ids: [])[:project_ids])
    projects = Project.active.where(id: ids)

    @dashboard.with_lock do
      projects.find_each do |project|
        @dashboard.dashboard_page_assignments.find_or_create_by!(project:)
      end
    end

    redirect_to projects_admin_dashboard_page_path(@dashboard), status: :see_other
  end

  def remove_project
    project = Project.find(params.expect(:project_id))
    @dashboard.with_lock do
      @dashboard.dashboard_page_assignments.find_by!(project:).destroy!
    end

    redirect_to projects_admin_dashboard_page_path(@dashboard), status: :see_other
  end

  private

  def find_dashboard
    @dashboard = ::Grids::DashboardPage.central.find(params.expect(:id))
  end

  def save_dashboard
    @dashboard.update!(params.expect(dashboard_page: [:name]))

    redirect_to edit_admin_dashboard_page_path(@dashboard), status: :see_other, notice: t(:notice_successful_update)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end
end
