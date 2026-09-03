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

module Costs
  class Engine < ::Rails::Engine
    engine_name :costs

    include OpenProject::Plugins::ActsAsOpEngine

    register "costs", author_url: "https://www.openproject.org", bundled: true, settings: { menu_item: :costs_settings } do
      project_module :costs do
        permission :view_time_entries,
                   {},
                   permissible_on: :project,
                   contract_actions: { time_entries: %i[read] }
        permission :view_own_time_entries,
                   {},
                   permissible_on: %i[work_package project],
                   contract_actions: { time_entries: %i[read_own] }

        permission :log_own_time,
                   {},
                   permissible_on: %i[work_package project],
                   require: :loggedin,
                   dependencies: :view_own_time_entries,
                   contract_actions: { time_entries: %i[create_own] }
        permission :log_time,
                   {},
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_time_entries,
                   contract_actions: { time_entries: %i[create] }

        permission :edit_own_time_entries,
                   {},
                   permissible_on: %i[work_package project],
                   require: :loggedin,
                   contract_actions: { time_entries: %i[edit_own destroy_own] }
        permission :edit_time_entries,
                   {},
                   permissible_on: :project,
                   require: :member,
                   contract_actions: { time_entries: %i[edit destroy] }

        permission :manage_project_activities,
                   {
                     "projects/settings/time_entry_activities": %i[show update],
                     "projects/settings/cost_types": %i[index toggle]
                   },
                   permissible_on: :project,
                   require: :member

        permission :view_own_hourly_rate,
                   {},
                   permissible_on: :project
        permission :view_hourly_rates,
                   {},
                   permissible_on: :project

        permission :edit_own_hourly_rate,
                   { hourly_rates: %i[edit update] },
                   permissible_on: :project,
                   require: :member

        permission :edit_hourly_rates,
                   { hourly_rates: %i[edit update] },
                   permissible_on: :project,
                   require: :member
        permission :view_cost_rates, # cost item values
                   {},
                   permissible_on: :project

        permission :log_own_costs, { costlog: %i[new create] },
                   permissible_on: :project,
                   require: :loggedin
        permission :log_costs, { costlog: %i[new create] },
                   permissible_on: :project,
                   require: :member

        permission :edit_own_cost_entries, { costlog: %i[edit update destroy] },
                   permissible_on: :project,
                   require: :loggedin
        permission :edit_cost_entries, { costlog: %i[edit update destroy] },
                   permissible_on: :project,
                   require: :member

        permission :view_cost_entries,
                   { costlog: [:index] },
                   permissible_on: :project
        permission :view_own_cost_entries,
                   { costlog: [:index] },
                   permissible_on: :project
      end

      # Menu extensions
      menu :admin_menu,
           :admin_costs,
           { controller: "/admin/time_settings", action: :show },
           if: Proc.new { User.current.admin? },
           caption: :project_module_costs,
           after: :enterprise,
           icon: "op-cost-reports"

      menu :admin_menu,
           :costs_settings,
           { controller: "/admin/time_settings", action: :show },
           if: Proc.new { User.current.admin? },
           caption: :label_defaults_and_limits,
           parent: :admin_costs

      menu :admin_menu,
           :cost_types,
           { controller: "/admin/cost_types", action: :index },
           if: ->(*) { User.current.admin? },
           parent: :admin_costs,
           caption: :label_cost_type_plural

      menu :admin_menu,
           :time_entry_activities,
           { controller: "/admin/settings/time_entry_activities", action: :index },
           if: ->(*) { User.current.admin? },
           parent: :admin_costs,
           caption: :enumeration_activities

      menu :global_menu,
           :my_time_tracking,
           { controller: "/my/time_tracking", action: "index", date: "today" },
           after: :my_page,
           caption: :label_my_time_tracking,
           if: ->(*) do
             User.current.allowed_in_any_project?(:log_own_time) || User.current.allowed_in_any_project?(:log_time)
           end,
           icon: :stopwatch

      menu :top_menu,
           :my_time_tracking,
           { controller: "/my/time_tracking", action: "index" },
           after: :my_page,
           context: :my,
           caption: :label_my_time_tracking,
           if: ->(*) do
             User.current.allowed_in_any_project?(:log_own_time) || User.current.allowed_in_any_project?(:log_time)
           end,
           icon: :stopwatch
    end

    initializer "costs.settings" do
      ::Settings::Definition.add "costs_currency", default: "€", format: :string
      ::Settings::Definition.add "costs_currency_format", default: "%n %u", format: :string, allowed: ["%u %n", "%n %u"]
      ::Settings::Definition.add "allow_tracking_start_and_end_times", default: false, format: :boolean
      ::Settings::Definition.add "enforce_tracking_start_and_end_times", default: false, format: :boolean
      ::Settings::Definition.add "time_entries_max_hours_per_entry", default: 0, format: :integer, allowed: (0..)
      ::Settings::Definition.add "time_entries_max_hours_per_day", default: 0, format: :integer, allowed: (0..)
      ::Settings::Definition.add "time_entries_prohibit_logging_on_non_working_days", default: false, format: :boolean
      ::Settings::Definition.add "time_entries_limit_to_user_working_hours", default: false, format: :boolean
      ::Settings::Definition.add "time_entries_prohibit_logging_for_past_months", default: false, format: :boolean
      ::Settings::Definition.add "time_entries_past_month_grace_days", default: 0, format: :integer, allowed: (0..)
    end

    activity_provider :time_entries, class_name: "Activities::TimeEntryActivityProvider", default: false

    patches %i[Project User PermittedParams WorkPackage]
    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :ActiveSupport, :NumberHelper, :NumberToCurrencyConverter

    add_tab_entry :user,
                  name: "rates",
                  partial: "users/rates",
                  path: ->(params) { edit_user_path(params[:user], tab: :rates) },
                  only_if: ->(*) { User.current.admin? },
                  label: :caption_rate_history

    add_api_path :cost_entry do |id|
      "#{root}/cost_entries/#{id}"
    end

    add_api_path :cost_entries_by_work_package do |id|
      "#{work_package(id)}/cost_entries"
    end

    add_api_path :summarized_work_package_costs_by_type do |id|
      "#{work_package(id)}/summarized_costs_by_type"
    end

    add_api_path :cost_type do |id|
      "#{root}/cost_types/#{id}"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::CostEntries::CostEntriesAPI
      mount ::API::V3::CostTypes::CostTypesAPI
      mount ::API::V3::TimeEntries::TimeEntriesAPI
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::CostEntries::CostEntriesByWorkPackageAPI
    end

    extend_api_response(:v3, :work_packages, :work_package) do
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper
      prepend API::V3::CostsApiUserPermissionCheck

      link :logCosts,
           cache_if: -> {
             current_user.allowed_in_project?(:log_costs, represented.project) ||
             current_user.allowed_in_project?(:log_own_costs, represented.project)
           } do
        next unless represented.costs_enabled? && represented.persisted?
        next unless represented.project&.cost_types_available?

        {
          href: new_work_packages_cost_entry_path(represented),
          type: "text/html",
          title: "Log costs on #{represented.subject}"
        }
      end

      link :showCosts,
           cache_if: -> {
             current_user.allowed_in_project?(:view_cost_entries, represented.project) ||
             current_user.allowed_in_project?(:view_own_cost_entries, represented.project)
           } do
        next unless represented.persisted? && represented.project&.costs_enabled?

        {
          href: cost_reports_path(represented.project_id,
                                  "fields[]": "WorkPackageId",
                                  "operators[WorkPackageId]": "=",
                                  "values[WorkPackageId]": represented.id,
                                  set_filter: 1),
          type: "text/html",
          title: "Show cost entries"
        }
      end

      property :labor_costs,
               exec_context: :decorator,
               if: ->(*) { labor_costs_visible? },
               skip_parse: true,
               render_nil: true,
               uncacheable: true

      property :material_costs,
               exec_context: :decorator,
               if: ->(*) { material_costs_visible? },
               skip_parse: true,
               render_nil: true,
               uncacheable: true

      property :overall_costs,
               exec_context: :decorator,
               if: ->(*) { overall_costs_visible? },
               skip_parse: true,
               render_nil: true,
               uncacheable: true

      resource :costsByType,
               link: ->(*) {
                 next unless costs_by_type_visible?

                 {
                   href: api_v3_paths.summarized_work_package_costs_by_type(represented.id)
                 }
               },
               getter: ->(*) {
                 ::API::V3::CostEntries::WorkPackageCostsByTypeRepresenter.new(represented, current_user:)
               },
               setter: ->(*) {},
               skip_render: ->(*) { !costs_by_type_visible? }

      send(:define_method, :overall_costs) do
        number_to_currency(represented.overall_costs)
      end

      send(:define_method, :labor_costs) do
        number_to_currency(represented.labor_costs)
      end

      send(:define_method, :material_costs) do
        number_to_currency(represented.material_costs)
      end
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      costs_visible = ->(*) { represented.project&.costs_enabled? }

      # Unit costs (and the overall total) require an available cost type.
      # instance_exec keeps `represented` bound to the decorator.
      unit_costs_visible = ->(*) {
        instance_exec(&costs_visible) && represented.project.cost_types_available?
      }

      # N.B. in the long term we should have a type like "Currency", but that requires a proper
      # format and not a string like "10 EUR"
      schema :overall_costs,
             type: "String",
             required: false,
             writable: false,
             show_if: unit_costs_visible

      schema :labor_costs,
             type: "String",
             required: false,
             writable: false,
             show_if: costs_visible

      schema :material_costs,
             type: "String",
             required: false,
             writable: false,
             show_if: unit_costs_visible

      schema :costs_by_type,
             type: "Collection",
             name_source: :spent_units,
             required: false,
             show_if: unit_costs_visible,
             writable: false
    end

    config.to_prepare do
      # Load Enumeration descendants due to STI
      TimeEntryActivity

      OpenProject::ProjectLatestActivity.register on: "TimeEntry"
      Costs::Patches::MembersPatch.mixin!

      ##
      # Add a new group
      cost_attributes = %i(costs_by_type labor_costs material_costs overall_costs)
      ::TypeVariant.add_default_group(:costs, :label_cost_plural)
      ::TypeVariant.add_default_mapping(:costs, *cost_attributes)

      # Unit costs (and the overall total they feed into) are meaningless without a
      # cost type, so they are hidden when none is available in the project.
      unit_costs_constraint = ->(_type, project: nil) {
        project.nil? || (project.costs_enabled? && project.cost_types_available?)
      }
      # Labor costs come from time entries and stay visible regardless.
      costs_constraint = ->(_type, project: nil) {
        project.nil? || project.costs_enabled?
      }

      ::TypeVariant.add_constraint :labor_costs, costs_constraint
      %i(costs_by_type material_costs overall_costs).each do |attribute|
        ::TypeVariant.add_constraint attribute, unit_costs_constraint
      end

      ::Queries::Register.register(::Query) do
        select Costs::QueryCurrencySelect
      end

      ::Queries::Register.register(::ProjectQuery) do
        filter ::Queries::Projects::Filters::AvailableCostTypesProjectsFilter
      end

      McpTools.register McpTools::CreateTimeEntry,
                        McpTools::DeleteTimeEntry,
                        McpTools::SearchTimeEntries,
                        McpTools::UpdateTimeEntry
    end
  end
end
