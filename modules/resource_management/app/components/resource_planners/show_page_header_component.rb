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

    def initialize(resource_planner:, project:)
      super

      @resource_planner = resource_planner
      @project = project
    end

    private

    def breadcrumb_items
      [
        { href: project_overview_path(@project.id), text: @project.name },
        { href: project_resource_planners_path(@project), text: t(:label_resource_management) },
        @resource_planner.name
      ]
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
      return true if User.current.active_admin?

      manage_planner?
    end

    def manage_planner?
      return false if @project.nil?

      owns_planner = @resource_planner.principal == User.current &&
        User.current.allowed_in_project?(:view_resource_planners, @project)
      can_manage_public = @resource_planner.public? &&
        User.current.allowed_in_project?(:manage_public_resource_planners, @project)

      owns_planner || can_manage_public
    end
  end
end
