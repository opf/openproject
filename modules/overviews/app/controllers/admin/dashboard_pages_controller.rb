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
  layout "admin"
  menu_item :standard_dashboards

  before_action :authorize_global
  before_action :find_dashboard, only: %i[edit update]
  before_action :load_projects, only: %i[new create edit update]

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

  def create
    @dashboard = ::Grids::DashboardPage.new(row_count: 1, column_count: 1)
    save_dashboard
  end

  def edit; end

  def update
    save_dashboard
  end

  private

  def find_dashboard
    @dashboard = ::Grids::DashboardPage.central.find(params[:id])
  end

  def load_projects
    @projects = Project.active.order(:name, :id)
  end

  def save_dashboard
    attributes = params.expect(dashboard_page: [:name, { project_ids: [] }])
    @dashboard.with_lock do
      @dashboard.update!(name: attributes[:name])
      update_assignments(attributes[:project_ids])
    end

    redirect_to edit_admin_dashboard_page_path(@dashboard), status: :see_other, notice: t(:notice_successful_update)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def update_assignments(project_ids)
    selected_ids = @projects.where(id: Array(project_ids).compact_blank).pluck(:id)
    assignments = @dashboard.dashboard_page_assignments
    assignments.where(project_id: @projects).where.not(project_id: selected_ids).delete_all
    assigned_ids = assignments.pluck(:project_id)

    (selected_ids - assigned_ids).each do |project_id|
      assignments.create!(project_id:)
    end
  end
end
