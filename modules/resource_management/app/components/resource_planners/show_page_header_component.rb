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

module ResourcePlanners
  class ShowPageHeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include ResourceManagement::PlannerRoutes

    def initialize(resource_planner:, selected_view: nil)
      super

      @resource_planner = resource_planner
      @project = resource_planner.project
      @selected_view = selected_view
    end

    private

    def selected_view_id
      @selected_view&.id || @resource_planner.default_view_id
    end

    def can_add_views?
      manage_planner?
    end

    # The timeframe is picked as a range, so it is either absent or complete.
    def timeframe_description
      start_date = @resource_planner.start_date
      end_date = @resource_planner.end_date
      return if start_date.nil? || end_date.nil?

      t("resource_management.timeframe.full", start: helpers.format_date(start_date), end: helpers.format_date(end_date))
    end

    def breadcrumb_items
      [
        ({ href: project_overview_path(@project.id), text: @project.name } if @project),
        { href: planners_path(@project), text: t(:label_resource_management) },
        @resource_planner.name
      ].compact
    end

    def favorited?
      @resource_planner.favorited_by?(User.current)
    end

    # Resource planners are favorited through their `PersistedView` base class,
    # mirroring the sidebar/index row action (see RowComponent#favorite_item).
    def favorite_path_for(planner)
      favorite_path(object_type: "persisted_views", object_id: planner.id)
    end

    def show_action_menu?
      edit_allowed? || delete_allowed?
    end

    def edit_allowed?
      manage_planner?
    end

    def delete_allowed?
      User.current.active_admin? || manage_planner?
    end

    def manage_planner?
      @resource_planner.manageable_by?(User.current)
    end
  end
end
