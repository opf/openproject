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

module OpenProject::Reporting
  class Engine < ::Rails::Engine
    engine_name :openproject_reporting

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-reporting",
             author_url: "https://www.openproject.org",
             bundled: true do
      view_actions = %i[index show drill_down available_values]
      edit_actions = %i[create update rename destroy]

      # register reporting_module including permissions
      project_module :costs do
        permission :save_cost_reports,
                   { cost_reports: edit_actions },
                   permissible_on: :project
        permission :save_private_cost_reports,
                   { cost_reports: edit_actions },
                   permissible_on: :project
      end

      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do
          # register additional permissions for viewing time and cost entries through the CostReportsController
          view_actions.each do |action|
            OpenProject::AccessControl.permission(:view_time_entries).controller_actions << "cost_reports/#{action}"
            OpenProject::AccessControl.permission(:view_own_time_entries).controller_actions << "cost_reports/#{action}"
            OpenProject::AccessControl.permission(:view_cost_entries).controller_actions << "cost_reports/#{action}"
            OpenProject::AccessControl.permission(:view_own_cost_entries).controller_actions << "cost_reports/#{action}"
          end

          OpenProject::AccessControl.permission(:view_time_entries).controller_actions << "cost_reports/menus/show"
          OpenProject::AccessControl.permission(:view_own_time_entries).controller_actions << "cost_reports/menus/show"
          OpenProject::AccessControl.permission(:view_cost_entries).controller_actions << "cost_reports/menus/show"
          OpenProject::AccessControl.permission(:view_own_cost_entries).controller_actions << "cost_reports/menus/show"
        end
      end

      should_render = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
          (
            User.current.allowed_in_any_project?(:view_time_entries) ||
              User.current.allowed_in_any_work_package?(:view_own_time_entries) ||
              User.current.allowed_in_any_project?(:view_cost_entries) ||
              User.current.allowed_in_any_project?(:view_own_cost_entries)
          )
      end

      # menu extensions
      menu :top_menu,
           :cost_reports_global,
           { controller: "/cost_reports", action: "index", project_id: nil },
           caption: :cost_reports_title,
           icon: "op-cost-reports",
           if: should_render

      menu :global_menu,
           :cost_reports_global,
           { controller: "/cost_reports", action: "index", project_id: nil },
           after: :news,
           caption: :cost_reports_title,
           icon: "op-cost-reports",
           if: should_render

      menu :global_menu,
           :cost_reports_global_report_menu,
           { controller: "/cost_reports", action: "index", project_id: nil },
           parent: :cost_reports_global,
           partial: "cost_reports/menus/menu",
           if: should_render

      menu :project_menu,
           :costs,
           { controller: "/cost_reports", action: "index" },
           after: :news,
           caption: :cost_reports_title,
           if: Proc.new { |project| project.module_enabled?(:costs) },
           icon: "op-cost-reports"

      menu :project_menu,
           :costs_menu,
           { controller: "/cost_reports", action: "index" },
           if: Proc.new { |project| project.module_enabled?(:costs) },
           partial: "cost_reports/menus/menu",
           parent: :costs
    end

    initializer "reporting.register_hooks" do
      # don't use require_dependency to not reload hooks in development mode
      require "open_project/reporting/hooks"
    end

    initializer "reporting.load_patches" do
      require_relative "patches/big_decimal_patch"
      require_relative "patches/to_date_patch"
    end

    initializer "reporting.configuration" do
      ::Settings::Definition.add "cost_reporting_cache_filter_classes",
                                 default: true,
                                 format: :boolean
    end

    patches %i[CustomFieldsController]
    patch_with_namespace :BasicData, :SettingSeeder
  end
end
