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
  class DashboardTabMenuComponent < ApplicationComponent
    def initialize(project:, current_user:, dashboard: nil)
      super()
      @project = project
      @dashboard = dashboard
      @dashboard_exists = dashboard.present? || ::Grids::Overview.exists?(project:, disabled: false)
      @can_manage_project = current_user.allowed_in_project?(:manage_dashboards, project)
      @can_manage_standard = dashboard&.central? && current_user.allowed_globally?(:manage_standard_dashboards)
      @can_copy = current_user.allowed_in_any_project?(:manage_dashboards)
    end

    def render?
      @can_manage_project || @can_manage_standard || (@can_copy && @dashboard_exists)
    end

    private

    def name
      @dashboard&.name || t("overviews.label_dashboard")
    end

    def edit_path
      if @can_manage_standard
        edit_admin_dashboard_page_path(@dashboard)
      elsif @can_manage_project && !@dashboard&.central?
        if @dashboard
          project_edit_settings_dashboard_page_path(@project, @dashboard)
        else
          dashboard_project_overview_path(@project, anchor: "dashboard-widgets")
        end
      end
    end

    def edit_label
      if @can_manage_standard
        t("overviews.dashboards.edit_standard")
      elsif @dashboard
        t("overviews.dashboards.edit_project")
      else
        t("overviews.dashboards.configure")
      end
    end

    def save_as_path
      return unless @can_copy && @dashboard_exists

      @dashboard ? save_as_project_dashboard_page_path(@project, @dashboard) : project_save_as_original_dashboard_path(@project)
    end

    def deactivate_path
      return unless @can_manage_project && @dashboard_exists

      if @dashboard
        deactivate_project_dashboard_page_path(@project, @dashboard)
      else
        project_deactivate_original_dashboard_path(@project)
      end
    end

    def rename_path
      if @can_manage_standard
        rename_dialog_admin_dashboard_page_path(@dashboard)
      elsif local_dashboard_manager?
        rename_dialog_project_dashboard_page_path(@project, @dashboard)
      end
    end

    def deletion_path
      if @can_manage_standard
        deletion_dialog_admin_dashboard_page_path(@dashboard)
      elsif local_dashboard_manager?
        deletion_dialog_project_dashboard_page_path(@project, @dashboard)
      end
    end

    def local_dashboard_manager?
      @can_manage_project && @dashboard && !@dashboard.central?
    end
  end
end
