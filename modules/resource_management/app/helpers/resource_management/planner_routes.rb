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
  # Resource planners are reachable both inside a project and globally. One route tree
  # serves both: the project segment is optional, and `ResourcePlanner#path_args`
  # supplies it or not.
  #
  # Every segment is named. A positional argument combined with any other keyword binds
  # to the first declared segment, which here is the optional `project_id` -- silently
  # producing a wrong URL or a generation error.
  #
  # The routes are resolved against the application's url helpers rather than the
  # includer's, so controllers, components and menus can all mix this in.
  module PlannerRoutes
    def planners_path(project) = op_routes.resource_planners_path(**scope_args(project))

    def new_planner_path(project) = op_routes.new_resource_planner_path(**scope_args(project))

    def menu_planners_path(project, **params) = op_routes.menu_resource_planners_path(**scope_args(project), **params)

    def planner_path(planner) = op_routes.resource_planner_path(**planner.path_args)

    def edit_planner_path(planner) = op_routes.edit_resource_planner_path(**planner.path_args)

    def toggle_public_planner_path(planner) = op_routes.toggle_public_resource_planner_path(**planner.path_args)

    def planner_views_path(planner) = op_routes.resource_planner_views_path(**planner.child_path_args)

    def new_planner_view_path(planner) = op_routes.new_resource_planner_view_path(**planner.child_path_args)

    def planner_view_path(planner, view) = op_routes.resource_planner_view_path(**planner.view_path_args(view))

    def edit_planner_view_path(planner, view) = op_routes.edit_resource_planner_view_path(**planner.view_path_args(view))

    def new_planner_view_user_path(planner, view)
      op_routes.new_user_resource_planner_view_path(**planner.view_path_args(view))
    end

    def planner_view_users_path(planner, view)
      op_routes.users_resource_planner_view_path(**planner.view_path_args(view))
    end

    def remove_planner_view_user_path(planner, view, user_id)
      op_routes.remove_user_resource_planner_view_path(**planner.view_path_args(view), user_id:)
    end

    def new_planner_view_work_package_path(planner, view)
      op_routes.new_work_package_resource_planner_view_path(**planner.view_path_args(view))
    end

    def planner_view_work_packages_path(planner, view)
      op_routes.work_packages_resource_planner_view_path(**planner.view_path_args(view))
    end

    def move_planner_view_work_package_path(planner, view, work_package_id, **params)
      op_routes.move_work_package_resource_planner_view_path(**planner.view_path_args(view), work_package_id:, **params)
    end

    def reorder_planner_view_work_package_path(planner, view, work_package_id)
      op_routes.reorder_work_package_resource_planner_view_path(**planner.view_path_args(view), work_package_id:)
    end

    def remove_planner_view_work_package_path(planner, view, work_package_id)
      op_routes.remove_work_package_resource_planner_view_path(**planner.view_path_args(view), work_package_id:)
    end

    # The progress and timeline routes nest the view as `view_id` rather than `id`.
    def edit_planner_view_work_package_progress_path(planner, view, work_package)
      op_routes.edit_resource_planner_view_work_package_progress_path(
        **planner.nested_view_path_args(view), work_package_id: work_package.id
      )
    end

    def planner_view_work_package_progress_path(planner, view, work_package)
      op_routes.resource_planner_view_work_package_progress_path(
        **planner.nested_view_path_args(view), work_package_id: work_package.id
      )
    end

    def planner_view_work_package_timeline_resources_path(planner, view, **params)
      op_routes.resource_planner_view_work_package_timeline_resources_path(**planner.nested_view_path_args(view), **params)
    end

    def planner_view_work_package_timeline_events_path(planner, view, **params)
      op_routes.resource_planner_view_work_package_timeline_events_path(**planner.nested_view_path_args(view), **params)
    end

    def planner_view_user_timeline_resources_path(planner, view, **params)
      op_routes.resource_planner_view_user_timeline_resources_path(**planner.nested_view_path_args(view), **params)
    end

    def planner_view_user_timeline_events_path(planner, view, **params)
      op_routes.resource_planner_view_user_timeline_events_path(**planner.nested_view_path_args(view), **params)
    end

    # Allocation dialogs hang off the work package or principal rather than the
    # planner, so they take the surrounding scope explicitly.
    def new_allocation_path(project, **params)
      op_routes.new_resource_allocation_path(**scope_args(project), **params)
    end

    def edit_allocation_path(project, allocation, **params)
      op_routes.edit_resource_allocation_path(**scope_args(project), id: allocation.id, **params)
    end

    def allocations_path(project, **params)
      op_routes.resource_allocations_path(**scope_args(project), **params)
    end

    def allocation_path(project, allocation, **params)
      op_routes.resource_allocation_path(**scope_args(project), id: allocation.id, **params)
    end

    def staffing_path(project) = op_routes.resource_management_staffing_path(**scope_args(project))

    def staffing_assign_path(project, allocation)
      op_routes.resource_management_staffing_assign_path(**scope_args(project), id: allocation.id)
    end

    def refresh_form_allocations_path(project)
      op_routes.refresh_form_resource_allocations_path(**scope_args(project))
    end

    def work_package_allocations_path(project, work_package, **params)
      op_routes.work_package_resource_allocations_path(**scope_args(project), work_package_id: work_package.id, **params)
    end

    def user_allocations_path(project, user, **params)
      op_routes.user_resource_allocations_path(**scope_args(project), user_id: user.id, **params)
    end

    private

    def op_routes = Rails.application.routes.url_helpers

    def scope_args(project) = project ? { project_id: project } : {}
  end
end
