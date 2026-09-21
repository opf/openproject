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
  # Links that follow whichever scope their subject already lives in: a planner's
  # own, or the one the page is rendered in. Both route families exist in their
  # own right, so a link that must reach a particular area names that area's
  # helper directly instead of coming through here.
  #
  # Each method names both helpers. The project family inserts `project` at
  # different points depending on the prefix (`edit_project_resource_planner`,
  # `move_work_package_project_resource_planner_view`), so it cannot be derived
  # from the global name except by string surgery that fails only at runtime.
  #
  # The routes are resolved against the application's url helpers rather than the
  # includer's, so controllers, components and menus can all mix this in.
  module PlannerRoutes
    def planners_path(project)
      scoped_route(project, :resource_planners_path, :project_resource_planners_path)
    end

    def new_planner_path(project)
      scoped_route(project, :new_resource_planner_path, :new_project_resource_planner_path)
    end

    def menu_planners_path(project, **params)
      scoped_route(project, :menu_resource_planners_path, :menu_project_resource_planners_path, **params)
    end

    def planner_path(planner)
      planner_route(planner, :resource_planner_path, :project_resource_planner_path)
    end

    def edit_planner_path(planner)
      planner_route(planner, :edit_resource_planner_path, :edit_project_resource_planner_path)
    end

    def toggle_public_planner_path(planner)
      planner_route(planner, :toggle_public_resource_planner_path, :toggle_public_project_resource_planner_path)
    end

    def planner_views_path(planner)
      planner_route(planner, :resource_planner_views_path, :project_resource_planner_views_path)
    end

    def new_planner_view_path(planner)
      planner_route(planner, :new_resource_planner_view_path, :new_project_resource_planner_view_path)
    end

    def planner_view_path(planner, view)
      planner_route(planner, :resource_planner_view_path, :project_resource_planner_view_path, view)
    end

    def edit_planner_view_path(planner, view)
      planner_route(planner, :edit_resource_planner_view_path, :edit_project_resource_planner_view_path, view)
    end

    def new_planner_view_user_path(planner, view)
      planner_route(planner, :new_user_resource_planner_view_path, :new_user_project_resource_planner_view_path, view)
    end

    def planner_view_users_path(planner, view)
      planner_route(planner, :users_resource_planner_view_path, :users_project_resource_planner_view_path, view)
    end

    def remove_planner_view_user_path(planner, view, user_id)
      planner_route(planner, :remove_user_resource_planner_view_path, :remove_user_project_resource_planner_view_path,
                    view, user_id:)
    end

    def new_planner_view_work_package_path(planner, view)
      planner_route(planner, :new_work_package_resource_planner_view_path,
                    :new_work_package_project_resource_planner_view_path, view)
    end

    def planner_view_work_packages_path(planner, view)
      planner_route(planner, :work_packages_resource_planner_view_path,
                    :work_packages_project_resource_planner_view_path, view)
    end

    def move_planner_view_work_package_path(planner, view, work_package_id, **params)
      planner_route(planner, :move_work_package_resource_planner_view_path,
                    :move_work_package_project_resource_planner_view_path, view, work_package_id:, **params)
    end

    def reorder_planner_view_work_package_path(planner, view, work_package_id)
      planner_route(planner, :reorder_work_package_resource_planner_view_path,
                    :reorder_work_package_project_resource_planner_view_path, view, work_package_id:)
    end

    def remove_planner_view_work_package_path(planner, view, work_package_id)
      planner_route(planner, :remove_work_package_resource_planner_view_path,
                    :remove_work_package_project_resource_planner_view_path, view, work_package_id:)
    end

    def edit_planner_view_work_package_progress_path(planner, view, work_package)
      planner_route(planner, :edit_resource_planner_view_work_package_progress_path,
                    :edit_project_resource_planner_view_work_package_progress_path, view, work_package)
    end

    def planner_view_work_package_progress_path(planner, view, work_package)
      planner_route(planner, :resource_planner_view_work_package_progress_path,
                    :project_resource_planner_view_work_package_progress_path, view, work_package)
    end

    def planner_view_work_package_timeline_resources_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_work_package_timeline_resources_path,
                    :project_resource_planner_view_work_package_timeline_resources_path, view, **params)
    end

    def planner_view_work_package_timeline_events_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_work_package_timeline_events_path,
                    :project_resource_planner_view_work_package_timeline_events_path, view, **params)
    end

    def planner_view_user_timeline_resources_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_user_timeline_resources_path,
                    :project_resource_planner_view_user_timeline_resources_path, view, **params)
    end

    def planner_view_user_timeline_events_path(planner, view, **params)
      planner_route(planner, :resource_planner_view_user_timeline_events_path,
                    :project_resource_planner_view_user_timeline_events_path, view, **params)
    end

    # Allocation dialogs hang off the work package or principal rather than the
    # planner, so they take the surrounding scope explicitly.
    def new_allocation_path(project, **params)
      scoped_route(project, :new_resource_allocation_path, :new_project_resource_allocation_path, **params)
    end

    def edit_allocation_path(project, allocation, **params)
      scoped_route(project, :edit_resource_allocation_path, :edit_project_resource_allocation_path,
                   allocation, **params)
    end

    def allocations_path(project, **params)
      scoped_route(project, :resource_allocations_path, :project_resource_allocations_path, **params)
    end

    def allocation_path(project, allocation, **params)
      scoped_route(project, :resource_allocation_path, :project_resource_allocation_path, allocation, **params)
    end

    def refresh_form_allocations_path(project)
      scoped_route(project, :refresh_form_resource_allocations_path, :refresh_form_project_resource_allocations_path)
    end

    def staffing_path(project)
      scoped_route(project, :resource_management_staffing_path, :project_resource_management_staffing_path)
    end

    def staffing_assign_path(project, allocation)
      scoped_route(project, :resource_management_staffing_assign_path,
                   :project_resource_management_staffing_assign_path, allocation)
    end

    def work_package_allocations_path(project, work_package, **params)
      scoped_route(project, :work_package_resource_allocations_path, :project_work_package_resource_allocations_path,
                   work_package, **params)
    end

    def user_allocations_path(project, user, **params)
      scoped_route(project, :user_resource_allocations_path, :project_user_resource_allocations_path, user, **params)
    end

    private

    def planner_route(planner, global_helper, project_helper, *, **)
      if planner.global?
        op_routes.public_send(global_helper, planner, *, **)
      else
        op_routes.public_send(project_helper, planner.project, planner, *, **)
      end
    end

    def scoped_route(project, global_helper, project_helper, *, **)
      if project
        op_routes.public_send(project_helper, project, *, **)
      else
        op_routes.public_send(global_helper, *, **)
      end
    end

    def op_routes = Rails.application.routes.url_helpers
  end
end
