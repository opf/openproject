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

module ResourceManagement
  # Resource planners are reachable both inside a project and globally, so every
  # link has to pick its route from the planner's own scope rather than from the
  # page it is rendered on.
  #
  # The routes are resolved against the application's url helpers rather than the
  # includer's, so controllers, components and menus can all mix this in.
  module PlannerRoutes
    def planners_path(project)
      project ? op_routes.project_resource_planners_path(project) : op_routes.resource_planners_path
    end

    def new_planner_path(project)
      project ? op_routes.new_project_resource_planner_path(project) : op_routes.new_resource_planner_path
    end

    def planner_path(planner)
      planner_route(planner, :resource_planner_path)
    end

    def edit_planner_path(planner)
      planner_route(planner, :edit_resource_planner_path)
    end

    def toggle_public_planner_path(planner)
      planner_route(planner, :toggle_public_resource_planner_path)
    end

    def planner_views_path(planner)
      planner_route(planner, :resource_planner_views_path)
    end

    def planner_view_path(planner, view)
      planner_route(planner, :resource_planner_view_path, view)
    end

    def new_planner_view_path(planner)
      planner_route(planner, :new_resource_planner_view_path)
    end

    def edit_planner_view_path(planner, view)
      planner_route(planner, :edit_resource_planner_view_path, view)
    end

    def new_planner_view_user_path(planner, view)
      planner_route(planner, :new_user_resource_planner_view_path, view)
    end

    def planner_view_users_path(planner, view)
      planner_route(planner, :users_resource_planner_view_path, view)
    end

    def remove_planner_view_user_path(planner, view, user_id)
      planner_route(planner, :remove_user_resource_planner_view_path, view, user_id:)
    end

    def new_planner_view_work_package_path(planner, view)
      planner_route(planner, :new_work_package_resource_planner_view_path, view)
    end

    def planner_view_work_packages_path(planner, view)
      planner_route(planner, :work_packages_resource_planner_view_path, view)
    end

    def move_planner_view_work_package_path(planner, view, work_package_id, **params)
      planner_route(planner, :move_work_package_resource_planner_view_path, view, work_package_id:, **params)
    end

    def reorder_planner_view_work_package_path(planner, view, work_package_id)
      planner_route(planner, :reorder_work_package_resource_planner_view_path, view, work_package_id:)
    end

    def remove_planner_view_work_package_path(planner, view, work_package_id)
      planner_route(planner, :remove_work_package_resource_planner_view_path, view, work_package_id:)
    end

    def edit_planner_view_work_package_progress_path(planner, view, work_package)
      planner_route(planner, :edit_resource_planner_view_work_package_progress_path, view, work_package)
    end

    def planner_view_work_package_timeline_resources_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_work_package_timeline_resources_path, view, **params)
    end

    def planner_view_work_package_timeline_events_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_work_package_timeline_events_path, view, **params)
    end

    def planner_view_user_timeline_resources_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_user_timeline_resources_path, view, **params)
    end

    def planner_view_user_timeline_events_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_user_timeline_events_path, view, **params)
    end

    # Allocation dialogs hang off the work package or principal rather than the
    # planner, so they take the surrounding scope explicitly.
    def new_allocation_path(project, **params)
      if project
        op_routes.new_project_resource_allocation_path(project, **params)
      else
        op_routes.new_resource_allocation_path(**params)
      end
    end

    def work_package_allocations_path(project, work_package, **params)
      if project
        op_routes.project_work_package_resource_allocations_path(project, work_package, **params)
      else
        op_routes.work_package_resource_allocations_path(work_package, **params)
      end
    end

    def user_allocations_path(project, user, **params)
      if project
        op_routes.project_user_resource_allocations_path(project, user, **params)
      else
        op_routes.user_resource_allocations_path(user, **params)
      end
    end

    private

    def op_routes
      Rails.application.routes.url_helpers
    end

    # Each project route is named like its global counterpart with `project_`
    # inserted before `resource_planner`, and the project prepended to the
    # arguments. PlannerRoutes' spec exercises every helper in both scopes so a
    # renamed route cannot slip through.
    def planner_route(planner, global_helper, *, **)
      if planner.global?
        op_routes.public_send(global_helper, planner, *, **)
      else
        project_helper = global_helper.to_s.sub("resource_planner", "project_resource_planner")
        op_routes.public_send(project_helper, planner.project, planner, *, **)
      end
    end
  end
end
