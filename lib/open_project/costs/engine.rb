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
require 'open_project/costs/version'

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
             :ProjectsController, :ApplicationHelper, :UsersHelper]
    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :BasicData, :SettingSeeder

    add_api_attribute on: :work_package, ar_name: :cost_object_id, api_name: :cost_object

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
      include API::V3::CostsAPIUserPermissionCheck

      link :log_costs do
        {
          href: new_work_packages_cost_entry_path(represented),
          type: 'text/html',
          title: "Log costs on #{represented.subject}"
        } if represented.costs_enabled? && current_user_allowed_to(:log_costs, context: represented.project)
      end

      link :timeEntries do
        {
          href: work_package_time_entries_path(represented.id),
          type: 'text/html',
          title: 'Time entries'
        } if user_has_time_entry_permissions?
      end

      linked_property :cost_object,
                      path: :budget,
                      title_getter: -> (*) { represented.cost_object.subject },
                      embed_as: ::API::V3::Budgets::BudgetRepresenter,
                      show_if: -> (*) { cost_object_visible? }

      property :labor_costs,
               exec_context: :decorator,
               if: -> (*) { labor_costs_visible? },
               render_nil: true

      property :material_costs,
               exec_context: :decorator,
               if: -> (*) { material_costs_visible? },
               render_nil: true

      property :overall_costs,
               exec_context: :decorator,
               if: -> (*) { overall_costs_visible? },
               render_nil: true

      linked_property :costs_by_type,
                      title_getter: -> (*) { nil },
                      getter: -> (*) { represented },
                      path: :summarized_work_package_costs_by_type,
                      embed_as: ::API::V3::CostEntries::WorkPackageCostsByTypeRepresenter,
                      show_if: -> (*) { costs_by_type_visible? }

      property :spent_time,
               if: ->(_) { user_has_time_entry_permissions? },
               inherit: true

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

    extend_api_response(:v3, :work_packages, :work_package_attribute_links) do
      linked_property :cost_object,
                      path: :budget,
                      namespace: :budgets,
                      show_if: ->(*) { costs_enabled? }
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
                                     link_factory: -> (budget) {
                                       {
                                         href: api_v3_paths.budget(budget.id),
                                         title: budget.subject
                                       }
                                     },
                                     show_if: -> (*) {
                                       represented.project && represented.project.costs_enabled?
                                     }
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_sums_schema) do
      schema :overall_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: -> (*) {
              ::Setting.work_package_list_summable_columns.include?('overall_costs')
             }
      schema :labor_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: -> (*) {
              ::Setting.work_package_list_summable_columns.include?('labor_costs')
             }
      schema :material_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: -> (*) {
              ::Setting.work_package_list_summable_columns.include?('material_costs')
             }
    end

    extend_api_response(:v3, :work_packages, :work_package_sums) do
      include ActionView::Helpers::NumberHelper

      property :overall_costs,
               exec_context: :decorator,
               getter: -> (*) {
                 number_to_currency(represented.overall_costs)

               },
               if: -> (*) {
                ::Setting.work_package_list_summable_columns.include?('overall_costs')
               }

      property :labor_costs,
               exec_context: :decorator,
               getter: -> (*) {
                 number_to_currency(represented.labor_costs)

               },
               if: -> (*) {
                ::Setting.work_package_list_summable_columns.include?('labor_costs')
               }

      property :material_costs,
               exec_context: :decorator,
               getter: -> (*) {
                 number_to_currency(represented.material_costs)
               },
               if: -> (*) {
                ::Setting.work_package_list_summable_columns.include?('material_costs')
               }

    end

    add_api_representer_cache_key(:v3, :work_packages, :schema, :work_package_schema) do
      if represented.project.module_enabled?('costs_module')
        ['costs_enabled']
      else
        ['costs_not_enabled']
      end
    end

    assets %w(costs/costs.css)

    initializer 'costs.register_hooks' do
      require 'open_project/costs/hooks'
      require 'open_project/costs/hooks/activity_hook'
      require 'open_project/costs/hooks/work_package_hook'
      require 'open_project/costs/hooks/work_package_action_menu'
      require 'open_project/costs/hooks/work_packages_show_attributes'
    end

    initializer 'costs.patch_number_helper' do |_app|
      # we have to do the patching in the initializer to make sure we only do this once in development
      # since the NumberHelper is not unloaded
      ActionView::Helpers::NumberHelper.send(:include, OpenProject::Costs::Patches::NumberHelperPatch)
    end

    initializer 'costs.register_latest_project_activity' do
      Project.register_latest_project_activity on: ::CostObject,
                                               attribute: :updated_on
    end

    module EagerLoadedCosts
      def add_eager_loading(*args)
        EagerLoadedCosts.join_costs(super)
      end

      def self.join_costs(scope)
        # The core adds a "LEFT OUTER JOIN time_entries" where the on clause
        # allows all time entries to be joined if he has the :view_time_entries.
        # Costs will add another "LEFT OUTER JOIN time_entries". The two joins
        # may or may not include each other's rows depending on the user's and the project's permissions.
        # This is caused by entries being joined if he has
        # the :view_time_entries permission and additionally those which are
        # his and for which he has the :view_own_time_entries permission.
        # Because of that, entries may be joined twice.
        # We therefore modify the core's join by placing it in a subquery similar to those of costs.
        #
        # This is very hacky.
        #
        # We also have to remove the sum calcualtion for time_entries.hours as
        # the calculation is later on performed within the subquery added by
        # LaborCosts. With it, we can use the value as it is calculated by the subquery.
        material = WorkPackage::MaterialCosts.new
        labor = WorkPackage::LaborCosts.new
        time = scope.dup

        wp_table = WorkPackage.arel_table
        time_join = wp_table
                    .outer_join(time.arel.as('spent_time_hours'))
                    .on(wp_table[:id].eq(time.arel_table.alias('spent_time_hours')[:id]))

        scope.joins_values.reject! do |join|
          join.is_a?(Arel::Nodes::OuterJoin) &&
            join.left.is_a?(Arel::Table) &&
            join.left.name == 'time_entries'
        end
        scope.select_values.reject! do |select|
          select == "SUM(time_entries.hours) AS hours"
        end

        material_scope = material.add_to_work_package_collection(scope.dup)
        labor_scope = labor.add_to_work_package_collection(scope.dup)

        target_scope = scope
                       .joins(material_scope.join_sources)
                       .joins(labor_scope.join_sources)
                       .joins(time_join.join_sources)
                       .select(material_scope.select_values)
                       .select(labor_scope.select_values)
                       .select('spent_time_hours.hours')

        target_scope.joins_values.reject! do |join|
          join.is_a?(Arel::Nodes::OuterJoin) &&
            join.left.is_a?(Arel::Nodes::TableAlias) &&
            join.left.right == 'descendants'
        end

        target_scope.group_values.reject! do |group|
          group == :id
        end

        target_scope
      end
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

      API::V3::WorkPackages::WorkPackageCollectionRepresenter.prepend EagerLoadedCosts

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
