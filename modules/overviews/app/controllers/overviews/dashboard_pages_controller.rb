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
    include SortableLists::DropRequestValidation

    configure_drop_request list_type: DashboardTabs::SORTABLE_LIST_TYPE, list_id_scoped: false

    menu_item :overview
    menu_item :settings_dashboards, only: %i[settings activate edit move]

    before_action :find_active_dashboard, only: %i[show save_as copy deactivate]
    before_action :find_owned_dashboard, only: %i[update destroy rename_dialog deletion_dialog]

    def show; end

    def new
      @dashboard = ::Grids::DashboardPage.new(project: @project)
      render_new_dialog
    end

    def edit
      if params[:id]
        @dashboard = ::Grids::DashboardPage.where(project: @project, disabled: false).find(params.expect(:id))
      elsif ::Grids::Overview.exists?(project: @project, disabled: true)
        raise ActiveRecord::RecordNotFound
      end
    end

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
      path = from_settings? ? settings_project_dashboard_pages_path(@project) : project_overview_path(@project)
      redirect_to path, status: :see_other, notice: t(:notice_successful_delete)
    end

    def rename_dialog
      @dashboard.name = @dashboard.display_name if @dashboard.is_a?(::Grids::Overview)
      render_rename_dialog
    end

    def deletion_dialog
      dialog = DeleteDashboardDialogComponent.new(dashboard: @dashboard, project: @project, from_settings: from_settings?)
      respond_with_dialog(dialog)
    end

    def save_as
      @copy = ::Grids::DashboardPage.new(name: @dashboard.name.presence || t("overviews.label_dashboard"),
                                         project: @project)
      render_save_as_dialog
    end

    def copy
      attributes = params.expect(dashboard_page: %i[name project_id])
      destination = target_projects.find(attributes[:project_id])
      @copy = Overviews::CopyDashboardService.new(user: current_user, source: @dashboard, project: destination)
        .call(name: attributes[:name])

      if @copy.persisted?
        redirect_to project_dashboard_page_path(destination, @copy), status: :see_other, notice: t(:notice_successful_create)
      else
        render_save_as_dialog(status: :unprocessable_entity)
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
      @dashboard_type = dashboard_type
      @dashboard_name = dashboard_name_filter
      @dashboard_filters = [{ name: { operator: "~", values: [@dashboard_name] } }].to_json if @dashboard_name
      @dashboard_tabs = filtered_dashboard_tabs

      render layout: !turbo_frame_request?
    end

    def move
      if valid_drop_request? && DashboardTabs.new(@project).move_after(params.expect(:tab_key), drop_params[:prev_id].presence)
        head :no_content
      else
        render_error_flash_message_via_turbo_stream(message: t(:error_invalid_list_move_anchor))
        respond_with_turbo_streams(status: :unprocessable_entity)
      end
    end

    def activate
      if params[:id]
        ::Grids::DashboardPage.in_project(@project).find(params.expect(:id)).set_active_in!(@project, active: true)
      else
        ::Grids::Overview.find_by!(project: @project).update!(disabled: false)
      end

      redirect_to settings_project_dashboard_pages_path(@project, dashboard_type:, filters: params.permit(:filters)[:filters]),
                  status: :see_other, notice: t(:notice_successful_update)
    end

    private

    def filtered_dashboard_tabs
      entries = DashboardTabs.new(@project).entries
      entries = entries.select(&:standard?) if @dashboard_type == "standard"
      entries = entries.reject(&:standard?) if @dashboard_type == "project"
      return entries unless @dashboard_name

      term = @dashboard_name.downcase
      entries.select { |entry| entry.display_name.downcase.include?(term) }
    end

    def dashboard_name_filter
      raw_filter = params.permit(:filters)[:filters]
      return if raw_filter.blank?

      filter = Queries::ParamsParser::APIV3FiltersParser.parse(raw_filter).find do |candidate|
        candidate[:attribute] == "name" && candidate[:operator] == "~"
      end
      Array(filter&.fetch(:values)).grep(String).first&.strip.presence
    rescue Queries::ParamsParser::MalformedParameterError
      nil
    end

    def from_settings?
      params.permit(:from_settings)[:from_settings] == "1"
    end

    def dashboard_type
      params.permit(:dashboard_type)[:dashboard_type].presence_in(%w[standard project])
    end

    def find_owned_dashboard
      @dashboard = if params[:id]
                     ::Grids::DashboardPage.where(project: @project).find(params.expect(:id))
                   else
                     ::Grids::Overview.find_by!(project: @project)
                   end
    end

    def render_rename_dialog(status: :ok)
      origin = from_settings? ? "1" : nil
      action = if @dashboard.is_a?(::Grids::Overview)
                 project_rename_original_dashboard_path(@project, from_settings: origin)
               else
                 project_dashboard_page_path(@project, @dashboard, from_settings: origin)
               end
      dialog = DashboardNameDialogComponent.new(
        dashboard: @dashboard,
        url: action,
        title: t("overviews.dashboards.rename"),
        submit: t(:button_rename)
      )
      respond_with_dialog(dialog, status:) do |format|
        format.html { render :rename, locals: { action: }, status: }
      end
    end

    def find_active_dashboard
      @dashboard = if params[:id]
                     ::Grids::DashboardPage.active_in(@project).find(params.expect(:id))
                   else
                     ::Grids::Overview.find_by!(project: @project, disabled: false)
                   end
    end

    def render_save_as_dialog(status: :ok)
      @target_projects = target_projects.order(:name, :id)
      action = if @dashboard.is_a?(::Grids::Overview)
                 project_copy_original_dashboard_path(@project)
               else
                 copy_project_dashboard_page_path(@project, @dashboard)
               end
      dialog = SaveDashboardAsDialogComponent.new(dashboard: @copy, url: action, projects: @target_projects)
      respond_with_dialog(dialog, status:) do |format|
        format.html { render :save_as, locals: { action: }, status: }
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
        path = if from_settings?
                 settings_project_dashboard_pages_path(@project)
               elsif @dashboard.is_a?(::Grids::Overview)
                 dashboard_project_overview_path(@project)
               else
                 project_dashboard_page_path(@project, @dashboard)
               end
        redirect_to path, status: :see_other, notice: t(notice)
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
