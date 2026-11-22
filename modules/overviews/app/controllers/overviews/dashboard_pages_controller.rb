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

module Overviews
  class DashboardPagesController < ::Grids::BaseInProjectController
    include OpTurbo::ComponentStream

    menu_item :overview
    menu_item :settings_dashboards, only: %i[settings activate edit]

    before_action :find_active_dashboard, only: %i[show edit update destroy rename_dialog deletion_dialog save_as copy deactivate]
    before_action :require_local_dashboard, only: %i[edit update destroy rename_dialog deletion_dialog]

    def show; end

    def new
      @dashboard = ::Grids::DashboardPage.new(project: @project)
      render_new_dialog
    end

    def edit; end

    def create
      @dashboard = ::Grids::DashboardPage.new(project: @project, row_count: 1, column_count: 1, **dashboard_attributes)
      save_dashboard(notice: :notice_successful_create) { render_new_dialog(status: :unprocessable_entity) }
    end

    def update
      @dashboard.assign_attributes(dashboard_attributes)
      save_dashboard(notice: :notice_successful_update) { render_rename_dialog(status: :unprocessable_entity) }
    end

    def destroy
      @dashboard.destroy!
      redirect_to project_overview_path(@project), status: :see_other, notice: t(:notice_successful_delete)
    end

    def rename_dialog
      render_rename_dialog
    end

    def deletion_dialog
      respond_with_dialog DeleteDashboardDialogComponent.new(dashboard: @dashboard, project: @project)
    end

    def save_as
      @target_projects = target_projects.order(:name, :id)
      @copy = ::Grids::DashboardPage.new(name: @dashboard.name.presence || t("overviews.label_dashboard"),
                                         project: @project)
    end

    def copy
      attributes = params.expect(dashboard_page: %i[name project_id])
      destination = target_projects.find(attributes[:project_id])
      @copy = Overviews::CopyDashboardService.new(user: current_user, source: @dashboard, project: destination)
        .call(name: attributes[:name])

      if @copy.persisted?
        redirect_to project_dashboard_page_path(destination, @copy), status: :see_other, notice: t(:notice_successful_create)
      else
        @target_projects = target_projects.order(:name, :id)
        render :save_as, status: :unprocessable_entity
      end
    end

    def deactivate
      if @dashboard.is_a?(::Grids::Overview)
        @dashboard.update!(disabled: true)
      else
        @dashboard.set_active_in!(@project, active: false)
      end

      redirect_to project_overview_path(@project), status: :see_other, notice: t(:notice_successful_update)
    end

    def settings
      @original_dashboard = ::Grids::Overview.find_by(project: @project)
      @dashboards = ::Grids::DashboardPage.in_project(@project).order(:name, :id)
      @active_ids = ::Grids::DashboardPage.active_in(@project).pluck(:id).to_set
    end

    def activate
      if params[:id]
        ::Grids::DashboardPage.in_project(@project).find(params.expect(:id)).set_active_in!(@project, active: true)
      else
        ::Grids::Overview.find_by!(project: @project).update!(disabled: false)
      end

      redirect_to settings_project_dashboard_pages_path(@project), status: :see_other, notice: t(:notice_successful_update)
    end

    private

    def require_local_dashboard
      raise ActiveRecord::RecordNotFound unless @dashboard.is_a?(::Grids::DashboardPage) && !@dashboard.central?
    end

    def render_rename_dialog(status: :ok)
      dialog = DashboardNameDialogComponent.new(
        dashboard: @dashboard,
        url: project_dashboard_page_path(@project, @dashboard),
        title: t("overviews.dashboards.rename"),
        submit: t(:button_rename)
      )
      respond_with_dialog(dialog, status:) do |format|
        format.html { render :edit, status: }
      end
    end

    def find_active_dashboard
      @dashboard = if params[:id]
                     ::Grids::DashboardPage.active_in(@project).find(params.expect(:id))
                   else
                     ::Grids::Overview.find_by!(project: @project, disabled: false)
                   end
    end

    def target_projects
      Project.active.allowed_to(current_user, :manage_dashboards)
    end

    def dashboard_attributes
      params.expect(dashboard_page: [:name]).to_h.symbolize_keys
    end

    def save_dashboard(notice:)
      if @dashboard.save
        redirect_to project_dashboard_page_path(@project, @dashboard), status: :see_other, notice: t(notice)
      else
        yield
      end
    end

    def render_new_dialog(status: :ok)
      dialog = DashboardNameDialogComponent.new(dashboard: @dashboard, url: project_dashboard_pages_path(@project))
      respond_with_dialog(dialog, status:) do |format|
        format.html { render :edit, status: }
      end
    end
  end
end
