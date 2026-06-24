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

    initializer "openproject-resource_management.feature_decisions" do
      OpenProject::FeatureDecisions.add :resource_management, allow_enabling: Rails.env.local?
    end

    replace_principal_references "ResourceAllocation" => %i[principal_id requested_by_id reviewed_by_id]

    register "openproject-resource_management",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {} do
      project_module :resource_management,
                     if: -> { OpenProject::FeatureDecisions.resource_management_active? } do
        # `view_resource_planners` gates access to all CRUD actions. The
        # per-record rules (only owners can change their own private planner;
        # only manage_public users can change public ones) live in the
        # contracts — the controller filter just establishes that the user
        # has *some* business in the resource planner area.
        permission :view_resource_planners,
                   {
                     "resource_management/resource_planners": %i[index show overview new create edit update destroy],
                     "resource_management/resource_planner_views": %i[show new create edit update destroy
                                                                      new_work_package add_work_package
                                                                      remove_work_package move_work_package
                                                                      reorder_work_package
                                                                      new_user add_user remove_user],
                     "resource_management/work_package_resource_allocations": %i[index],
                     "resource_management/user_resource_allocations": %i[index],
                     "resource_management/menus": %i[show]
                   },
                   permissible_on: :project

        # Beyond this permission, the contract additionally requires the planner
        # itself to be public.
        permission :manage_public_resource_planners,
                   { "resource_management/resource_planners": %i[toggle_public] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planners]

        # The `contract_actions` map keeps the permission discoverable for the
        # API contracts that consume it via `allowed_in_project?`.
        permission :allocate_user_resources,
                   { "resource_management/resource_allocations": %i[new step refresh_form create edit update destroy] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planners],
                   contract_actions: { resource_allocation: %i[create update destroy] }
      end

      # TODO: Add those menus when global overview will be implemented
      #    should_render_global_menu_item = Proc.new do
      #      (User.current.logged? || !Setting.login_required?) &&
      #        User.current.allowed_in_any_project?(:view_resources) &&
      #        OpenProject::FeatureDecisions.resource_management_active?
      #    end

      #    menu :global_menu,
      #         :resource_management,
      #         { controller: "/resource_management/resource_management", action: :overview },
      #         caption: :label_resource_management,
      #         after: :calendar_view,
      #         icon: "people",
      #         if: should_render_global_menu_item

      #    menu :top_menu,
      #         :resource_management,
      #         { controller: "/resource_management/resource_management", action: :overview },
      #         context: :modules,
      #         caption: :label_resource_management,
      #         after: :calendar_view,
      #         icon: "people",
      #         if: should_render_global_menu_item

      menu :project_menu,
           :resource_management,
           { controller: "/resource_management/resource_planners", action: :index },
           caption: :label_resource_management,
           after: :work_packages,
           icon: "people"

      menu :project_menu,
           :resource_planners_menu,
           { controller: "/resource_management/resource_planners", action: :index },
           parent: :resource_management,
           partial: "resource_management/menus/menu",
           last: true,
           caption: :label_resource_management
    end
  end
end
