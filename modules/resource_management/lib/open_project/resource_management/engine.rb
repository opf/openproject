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

require "open_project/plugins"

module OpenProject::ResourceManagement
  class Engine < ::Rails::Engine
    engine_name :openproject_resource_management

    include OpenProject::Plugins::ActsAsOpEngine

    patches %i[PlaceholderUser]

    replace_principal_references "ResourceAllocation" => %i[principal_id requested_by_id reviewed_by_id
                                                            principal_assigned_by_id]

    register "openproject-resource_management",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {} do
      project_module :resource_management,
                     enterprise_feature: "resource_management" do
        permission :view_resource_planners,
                   {
                     "resource_management/resource_planners": %i[index show overview new create edit update destroy],
                     "resource_management/resource_planner_views": %i[show new create edit update destroy
                                                                      new_work_package add_work_package
                                                                      remove_work_package move_work_package
                                                                      reorder_work_package
                                                                      new_user add_user remove_user],
                     "resource_management/work_package_resource_allocations": %i[index],
                     "resource_management/work_package_timeline/resources": %i[index],
                     "resource_management/work_package_timeline/events": %i[index],
                     "resource_management/user_timeline/resources": %i[index],
                     "resource_management/user_timeline/events": %i[index],
                     "resource_management/user_resource_allocations": %i[index],
                     "resource_management/menus": %i[show]
                   },
                   permissible_on: :project

        permission :manage_public_resource_planners,
                   { "resource_management/resource_planners": %i[toggle_public] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planners]

        permission :view_global_resource_planners,
                   {},
                   permissible_on: :global,
                   require: :loggedin

        permission :manage_public_global_resource_planners,
                   {},
                   permissible_on: :global,
                   require: :loggedin,
                   dependencies: %i[view_global_resource_planners]

        permission :allocate_user_resources,
                   { "resource_management/resource_allocations": %i[new refresh_form create edit update destroy] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planners],
                   contract_actions: { resource_allocation: %i[create update destroy] }

        # Independent of `allocate_user_resources`: a user may be allowed to staff
        # without being allowed to create or edit allocations.
        permission :assign_users_to_generic_allocations,
                   { "resource_management/staffing": %i[index assign_form assign] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planners]
      end

      # Menu items outside a project are not permission-filtered by the menu
      # manager, so this proc is the only gate.
      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
          (User.current.allowed_globally?(:view_global_resource_planners) ||
            User.current.allowed_in_any_project?(:view_resource_planners))
      end

      menu :global_menu,
           :resource_management,
           { controller: "/resource_management/resource_planners", action: :index, project_id: nil },
           caption: :label_resource_management,
           after: :work_packages,
           icon: "people",
           enterprise_feature: "resource_management",
           if: should_render_global_menu_item

      menu :global_menu,
           :resource_planners_menu,
           { controller: "/resource_management/resource_planners", action: :index },
           parent: :resource_management,
           partial: "resource_management/menus/menu",
           last: true,
           caption: :label_resource_management,
           if: should_render_global_menu_item

      menu :top_menu,
           :resource_management,
           { controller: "/resource_management/resource_planners", action: :index, project_id: nil },
           context: :modules,
           caption: :label_resource_management,
           after: :work_packages,
           icon: "people",
           enterprise_feature: "resource_management",
           if: should_render_global_menu_item

      menu :project_menu,
           :resource_management,
           { controller: "/resource_management/resource_planners", action: :index },
           caption: :label_resource_management,
           after: :work_packages,
           icon: "people",
           enterprise_feature: "resource_management"

      menu :project_menu,
           :resource_planners_menu,
           { controller: "/resource_management/resource_planners", action: :index },
           parent: :resource_management,
           partial: "resource_management/menus/menu",
           last: true,
           caption: :label_resource_management
    end

    initializer "resource_management.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:manage_placeholder_user)
                                  .controller_actions
                                  .push(
                                    "resource_management/placeholder_users/new",
                                    "resource_management/placeholder_users/create"
                                  )
      end
    end

    add_api_path :allocatable_principals do
      "#{root}/allocatable_principals"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::AllocatablePrincipals::AllocatablePrincipalsAPI
    end
  end
end
