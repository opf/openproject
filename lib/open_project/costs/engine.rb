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
             requires_openproject: '>= 4.0.0',
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
           html: { class: 'icon2 icon-tracker' },
           caption: :label_cost_type_plural

      menu :project_menu,
           :cost_objects,
           { controller: '/cost_objects', action: 'index' },
           param: :project_id,
           before: :settings,
           caption: :cost_objects_title,
           html: { class: 'icon2 icon-budget' }

      Redmine::Activity.map do |activity|
        activity.register :cost_objects, class_name: 'Activity::CostObjectActivityProvider', default: false
      end
    end

    patches [:WorkPackage, :Project, :Query, :User, :TimeEntry, :PermittedParams,
             :ProjectsController, :ApplicationHelper, :UsersHelper, :WorkPackagesHelper]
    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    patch_with_namespace :BasicData, :RoleSeeder

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
                      show_if: -> (*) { represented.costs_enabled? }

      property :overall_costs,
               exec_context: :decorator,
               if: -> (*) { represented.costs_enabled? }

      linked_property :costs_by_type,
                      title_getter: -> (*) { nil },
                      getter: -> (*) { represented },
                      path: :summarized_work_package_costs_by_type,
                      embed_as: ::API::V3::CostEntries::WorkPackageCostsByTypeRepresenter,
                      show_if: -> (*) {
                        represented.costs_enabled? &&
                          (current_user_allowed_to(:view_cost_entries, context: represented.project) ||
                           current_user_allowed_to(:view_own_cost_entries, context: represented.project))
                      }

      property :spent_time,
               getter: -> (*) do
                 formatter = API::V3::Utilities::DateTimeFormatter
                 formatter.format_duration_from_hours(represented.spent_hours)
               end,
               writeable: false,
               exec_context: :decorator,
               if: -> (_) { user_has_time_entry_permissions? }

      send(:define_method, :overall_costs) do
        number_to_currency(attributes_helper.overall_costs)
      end

      send(:define_method, :attributes_helper) do
        @attributes_helper ||= OpenProject::Costs::AttributesHelper.new(represented)
      end

      send(:define_method, :cost_object) do
        represented.cost_object
      end

      send(:define_method, :user_has_time_entry_permissions?) do
        current_user_allowed_to(:view_time_entries, context: represented.project) ||
          (current_user_allowed_to(:view_own_time_entries, context: represented.project) && represented.costs_enabled?)
      end
    end

    extend_api_response(:v3, :work_packages, :work_package_attribute_links) do
      linked_property :cost_object,
                      path: :budget,
                      namespace: :budgets,
                      show_if: -> (*) { represented.costs_enabled? }
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      schema :spent_time,
             type: 'Duration',
             writable: false,
             show_if: -> (*) {
               current_user_allowed_to(:view_time_entries, context: represented.project) ||
                 (current_user_allowed_to(:view_own_time_entries, context: represented.project) &&
                     represented.project.costs_enabled?)
             }

      # N.B. in the long term we should have a type like "Currency", but that requires a proper
      # format and not a string like "10 EUR"
      schema :overall_costs,
             type: 'String',
             required: false,
             writable: false,
             show_if: -> (*) { represented.project.costs_enabled? }

      schema :costs_by_type,
             type: 'Collection',
             name_source: :spent_units,
             required: false,
             writable: false,
             show_if: -> (*) {
               represented.project.costs_enabled? &&
                 (current_user_allowed_to(:view_cost_entries, context: represented.project) ||
                 current_user_allowed_to(:view_own_cost_entries, context: represented.project))
             }

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
                                       represented.project.costs_enabled?
                                     }
    end

    assets %w(costs/costs.css
              costs/costs.js
              work_packages/cost_object.html
              work_packages/summarized_cost_entries.html)

    initializer 'costs.register_hooks' do
      require 'open_project/costs/hooks'
      require 'open_project/costs/hooks/activity_hook'
      require 'open_project/costs/hooks/work_package_hook'
      require 'open_project/costs/hooks/project_hook'
      require 'open_project/costs/hooks/work_package_action_menu'
      require 'open_project/costs/hooks/work_packages_show_attributes'
    end

    initializer 'costs.register_observers' do |_app|
      # Observers
      ActiveRecord::Base.observers.push :rate_observer, :default_hourly_rate_observer, :costs_work_package_observer
    end

    initializer 'costs.patch_number_helper' do |_app|
      # we have to do the patching in the initializer to make sure we only do this once in development
      # since the NumberHelper is not unloaded
      ActionView::Helpers::NumberHelper.send(:include, OpenProject::Costs::Patches::NumberHelperPatch)
    end

    config.to_prepare do
      # loading the class so that acts_as_journalized gets registered
      VariableCostObject

      # TODO: this recreates the original behaviour
      # however, it might not be desirable to allow assigning of cost_object regardless of the permissions
      PermittedParams.permit(:new_work_package, :cost_object_id)
    end

    config.to_prepare do |_app|
      NonStupidDigestAssets.whitelist << /work_packages\/.*\.html/
    end
  end
end
