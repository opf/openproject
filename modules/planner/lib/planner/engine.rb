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

module Planner
  class Engine < ::Rails::Engine
    engine_name :openproject_planner

    include OpenProject::Plugins::ActsAsOpEngine

    register "planner",
             author_url: "https://www.openproject.org",
             bundled: true do
      visible = ->(*) { User.current.logged? && OpenProject::FeatureDecisions.planner_active? }

      menu :global_menu,
           :planner,
           { controller: "/planner/views", action: "show", view: "today" },
           after: :my_page,
           caption: :label_planner,
           icon: "calendar",
           if: visible

      menu :global_menu,
           :planner_views,
           { controller: "/planner/views", action: "show", view: "today" },
           parent: :planner,
           partial: "planner/menus/menu",
           if: visible

      menu :top_menu,
           :planner,
           { controller: "/planner/views", action: "show", view: "today" },
           context: :my,
           after: :my_page,
           caption: :label_planner,
           icon: "calendar",
           if: visible
    end

    initializer "planner.feature_decisions" do
      OpenProject::FeatureDecisions.add :planner,
                                        description: "My planner: personal Today, Upcoming, Overdue and Completed views."
    end

    initializer "planner.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:view_work_packages)
          .controller_actions
          .push(
            "planner/views/show",
            "planner/menus/show"
          )

        OpenProject::AccessControl.permission(:add_work_packages)
          .controller_actions
          .push(
            "planner/tasks/new_dialog",
            "planner/tasks/create"
          )

        OpenProject::AccessControl.permission(:edit_work_packages)
          .controller_actions
          .push(
            "planner/tasks/update",
            "planner/tasks/plan",
            "planner/tasks/drop"
          )

        OpenProject::AccessControl.permission(:delete_work_packages)
          .controller_actions
          .push(
            "planner/tasks/destroy"
          )
      end
    end

    initializer "planner.event_subscriptions" do
      Rails.application.config.after_initialize do
        OpenProject::Notifications.subscribe(OpenProject::Events::MEMBER_DESTROYED) do |payload|
          Planner::OrphanedProjectService.new(payload[:member]).call
        end
      end
    end
  end
end
