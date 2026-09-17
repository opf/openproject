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
  module PlannerRoutes
    def planners_path(project)
      project ? project_resource_planners_path(project) : resource_planners_path
    end

    def new_planner_path(project)
      project ? new_project_resource_planner_path(project) : new_resource_planner_path
    end

    def planner_path(planner)
      if planner.global?
        resource_planner_path(planner)
      else
        project_resource_planner_path(planner.project, planner)
      end
    end

    def edit_planner_path(planner)
      if planner.global?
        edit_resource_planner_path(planner)
      else
        edit_project_resource_planner_path(planner.project, planner)
      end
    end

    def planner_views_path(planner)
      if planner.global?
        resource_planner_views_path(planner)
      else
        project_resource_planner_views_path(planner.project, planner)
      end
    end

    def new_planner_view_path(planner)
      if planner.global?
        new_resource_planner_view_path(planner)
      else
        new_project_resource_planner_view_path(planner.project, planner)
      end
    end

    def planner_view_path(planner, view)
      if planner.global?
        resource_planner_view_path(planner, view)
      else
        project_resource_planner_view_path(planner.project, planner, view)
      end
    end

    def toggle_public_planner_path(planner)
      if planner.global?
        toggle_public_resource_planner_path(planner)
      else
        toggle_public_project_resource_planner_path(planner.project, planner)
      end
    end
  end
end
