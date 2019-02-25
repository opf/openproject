#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'open_project/plugins'


module OpenProject::Costs
  class Engine < ::Rails::Engine
    engine_name :openproject_costs

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-costs',
             author_url: 'http://finn.de',
             requires_openproject: "= #{OpenProject::Costs::VERSION}",
             settings: {
               default: { 'costs_currency' => 'EUR','costs_currency_format' => '%n %u' },
               partial: 'settings/openproject_costs'
             },
             name: 'OpenProject Costs' do

      project_module :costs_module do
        permission :view_own_hourly_rate, {}
        permission :view_hourly_rates, {}

        permission :edit_own_hourly_rate, { hourly_rates: [:set_rate, :edit, :update] },
                   require: :member
        permission :edit_hourly_rates, { hourly_rates: [:set_rate, :edit, :update] },
                   require: :member
        permission :view_cost_rates, {} # cost item values

        permission :log_own_costs, { costlog: [:new, :create] },
                   require: :loggedin
        permission :log_costs, { costlog: [:new, :create] },
                   require: :member

        permission :edit_own_cost_entries, { costlog: [:edit, :update, :destroy] },
                   require: :loggedin
        permission :edit_cost_entries, { costlog: [:edit, :update, :destroy] },
                   require: :member

        permission :view_cost_objects, { cost_objects: [:index, :show] }

        permission :view_cost_entries, { cost_objects: [:index, :show], costlog: [:index] }
        permission :view_own_cost_entries, { cost_objects: [:index, :show], costlog: [:index] }

        permission :edit_cost_objects, { cost_objects: [:index, :show, :edit, :update, :destroy, :new, :create, :copy] }
      end

      # register additional permissions for the time log
      project_module :time_tracking do
        permission :view_own_time_entries, { timelog: [:index, :report] }
      end

      # Menu extensions
      menu :admin_menu,
           :cost_types,
           { controller: '/cost_types', action: 'index' },
           icon: 'icon2 icon-cost-types',
           caption: :label_cost_type_plural

      menu :project_menu,
           :cost_objects,
           { controller: '/cost_objects', action: 'index' },
           param: :project_id,
           before: :settings,
           caption: :cost_objects_title,
           icon: 'icon2 icon-budget'

      Redmine::Activity.map do |activity|
        activity.register :cost_objects, class_name: 'Activity::CostObjectActivityProvider', default: false
      end
    end

    patches [:Project, :User, :TimeEntry, :PermittedParams,
             :ProjectsController, :ApplicationHelper]
    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :ActiveSupport, :NumberHelper, :NumberToCurrencyConverter

    add_tab_entry :user,
                  name: 'rates',
                  partial: 'users/rates',
                  label: :caption_rate_history

    add_api_attribute on: :work_package, ar_name: :cost_object_id

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

    add_api_path :budget do |id|
      "#{root}/budgets/#{id}"
    end

    add_api_path :variable_cost_object do |id|
      "#{root}/budgets/#{id}"
    end

    add_api_path :budgets_by_project do |project_id|
      "#{project(project_id)}/budgets"
    end

    add_api_path :attachments_by_budget do |id|
      "#{budget(id)}/attachments"
    end

    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::Budgets::BudgetsAPI
      mount ::API::V3::CostEntries::CostEntriesAPI
      mount ::API::V3::CostTypes::CostTypesAPI
    end

    add_api_endpoint 'API::V3::Projects::ProjectsAPI', :id do
      mount ::API::V3::Budgets::BudgetsByProjectAPI
    end

    add_api_endpoint 'API::V3::WorkPackages::WorkPackagesAPI', :id do
      mount ::API::V3::CostEntries::CostEntriesByWorkPackageAPI
    end

    extend_api_response(:v3, :work_packages, :work_package) do
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper
      prepend API::V3::CostsAPIUserPermissionCheck

      link :logCosts,
           cache_if: -> {
             current_user_allowed_to(:log_costs, context: represented.project) ||
               current_user_allowed_to(:log_own_costs, context: represented.project) } do
        next unless represented.costs_enabled? && represented.persisted?

        {
          href: new_work_packages_cost_entry_path(represented),
          type: 'text/html',
          title: "Log costs on #{represented.subject}"
        }
      end

      link :showCosts,
           cache_if: -> { current_user_allowed_to(:view_cost_entries, context: represented.project) ||
                          current_user_allowed_to(:view_own_cost_entries, context: represented.project) } do
        next unless represented.cost_reporting_enabled? && represented.persisted?

        {
            href: work_packages_cost_entries_path(represented),
            type: 'text/html',
            title: "Show cost entries"
        }
      end

      associated_resource :cost_object,
                          v3_path: :budget,
                          link_title_attribute: :subject,
                          representer: ::API::V3::Budgets::BudgetRepresenter,
                          skip_render: ->(*) { !cost_object_visible? }

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
                 ::API::V3::CostEntries::WorkPackageCostsByTypeRepresenter.new(represented, current_user: current_user)
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

      send(:define_method, :cost_object) do
        represented.cost_object
      end
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      # N.B. in the long term we should have a type like "Currency", but that requires a proper
      # format and not a string like "10 EUR"
      schema :overall_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) { represented.project && represented.project.costs_enabled? }

      schema :labor_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) { represented.project && represented.project.costs_enabled? }

      schema :material_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) { represented.project && represented.project.costs_enabled? }

      schema :costs_by_type,
             type: 'Collection',
             name_source: :spent_units,
             required: false,
             show_if: ->(*) { represented.project && represented.project.costs_enabled? },
             writable: false

      schema_with_allowed_collection :cost_object,
                                     type: 'Budget',
                                     required: false,
                                     value_representer: ::API::V3::Budgets::BudgetRepresenter,
                                     link_factory: ->(budget) {
                                       {
                                         href: api_v3_paths.budget(budget.id),
                                         title: budget.subject
                                       }
                                     },
                                     show_if: ->(*) {
                                       represented.project && represented.project.costs_enabled?
                                     }
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_sums_schema) do
      schema :overall_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) {
               ::Setting.work_package_list_summable_columns.include?('overall_costs')
             }
      schema :labor_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) {
               ::Setting.work_package_list_summable_columns.include?('labor_costs')
             }
      schema :material_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: ->(*) {
               ::Setting.work_package_list_summable_columns.include?('material_costs')
             }
    end

    extend_api_response(:v3, :work_packages, :work_package_sums) do
      include ActionView::Helpers::NumberHelper

      property :overall_costs,
               exec_context: :decorator,
               getter: ->(*) {
                 number_to_currency(represented.overall_costs)
               },
               if: ->(*) {
                 ::Setting.work_package_list_summable_columns.include?('overall_costs')
               }

      property :labor_costs,
               exec_context: :decorator,
               getter: ->(*) {
                 number_to_currency(represented.labor_costs)
               },
               if: ->(*) {
                 ::Setting.work_package_list_summable_columns.include?('labor_costs')
               }

      property :material_costs,
               exec_context: :decorator,
               getter: ->(*) {
                 number_to_currency(represented.material_costs)
               },
               if: ->(*) {
                 ::Setting.work_package_list_summable_columns.include?('material_costs')
               }
    end

    assets %w(costs/costs.css)

    initializer 'costs.register_hooks' do
      require 'open_project/costs/hooks'
      require 'open_project/costs/hooks/activity_hook'
      require 'open_project/costs/hooks/work_package_hook'
      require 'open_project/costs/hooks/work_package_action_menu'
      require 'open_project/costs/hooks/work_packages_show_attributes'
    end

    initializer 'costs.register_latest_project_activity' do
      Project.register_latest_project_activity on: ::CostObject,
                                               attribute: :updated_on
    end

    config.to_prepare do
      require 'open_project/costs/patches/members_patch'
      OpenProject::Costs::Members.mixin!

      require 'open_project/costs/patches/work_package_patch'
      OpenProject::Costs::Patches::WorkPackagePatch.mixin!

      # loading the class so that acts_as_journalized gets registered
      VariableCostObject

      # TODO: this recreates the original behaviour
      # however, it might not be desirable to allow assigning of cost_object regardless of the permissions
      PermittedParams.permit(:new_work_package, :cost_object_id)

      require 'api/v3/work_packages/work_package_representer'

      API::V3::WorkPackages::WorkPackageRepresenter.to_eager_load += [:cost_object]

      require 'open_project/costs/patches/work_package_eager_loading_patch'
      API::V3::WorkPackages::WorkPackageEagerLoadingWrapper.prepend OpenProject::Costs::Patches::WorkPackageEagerLoadingPatch
      ##
      # Add a new group
      cost_attributes = %i(cost_object costs_by_type labor_costs material_costs overall_costs)
      ::Type.add_default_group(:costs, :label_cost_plural)
      ::Type.add_default_mapping(:costs, *cost_attributes)

      constraint = ->(_type, project: nil) {
        project.nil? || project.costs_enabled?
      }

      cost_attributes.each do |attribute|
        ::Type.add_constraint attribute, constraint
      end

      Queries::Register.filter Query, OpenProject::Costs::WorkPackageFilter
      Queries::Register.column Query, OpenProject::Costs::QueryCurrencyColumn
    end
  end
end
