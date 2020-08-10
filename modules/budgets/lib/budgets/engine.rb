module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    register 'budgets',
             author_url: 'https://www.openproject.com',
             bundled: true,
             name: 'Budgets' do
      project_module :budgets do
        permission :view_cost_objects, { cost_objects: %i[index show] }
        permission :edit_cost_objects, { cost_objects: %i[index show edit update destroy new create copy] }
      end

      menu :project_menu,
           :cost_objects,
           { controller: '/cost_objects', action: 'index' },
           param: :project_id,
           before: :settings,
           caption: :cost_objects_title,
           icon: 'icon2 icon-budget'
    end

    activity_provider :cost_objects, class_name: 'Activities::CostObjectActivityProvider', default: false

    #patches %i[Project User TimeEntry PermittedParams ProjectsController ApplicationHelper]
    #patch_with_namespace :WorkPackages, :BaseContract
    #patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    #patch_with_namespace :BasicData, :RoleSeeder
    #patch_with_namespace :BasicData, :SettingSeeder
    #patch_with_namespace :ActiveSupport, :NumberHelper, :NumberToCurrencyConverter

    add_api_attribute on: :work_package, ar_name: :cost_object_id

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
    end

    add_api_endpoint 'API::V3::Projects::ProjectsAPI', :id do
      mount ::API::V3::Budgets::BudgetsByProjectAPI
    end

    extend_api_response(:v3, :work_packages, :work_package) do
      # TODO: move to work package representer
      associated_resource :cost_object,
                          v3_path: :budget,
                          link_title_attribute: :subject,
                          representer: ::API::V3::Budgets::BudgetRepresenter,
                          skip_render: ->(*) { !cost_object_visible? }

      send(:define_method, :cost_object) do
        represented.cost_object
      end
    end

    # This should not be necessary as the payload representer inherits
    # from the work package representer. The patching probably happens after
    # the payload representer is already evaluated.
    extend_api_response(:v3, :work_packages, :work_package_payload) do
      prepend API::V3::CostsApiUserPermissionCheck

      associated_resource :cost_object,
                          v3_path: :budget,
                          link_title_attribute: :subject,
                          representer: ::API::V3::Budgets::BudgetRepresenter,
                          skip_render: ->(*) { !cost_object_visible? }
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
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
                                       represented.project&.module_enabled?(:budgets)
                                     }
    end

    initializer 'costs.register_latest_project_activity' do
      Project.register_latest_project_activity on: 'CostObject',
                                               attribute: :updated_on
    end

    config.to_prepare do
      # loading the class so that acts_as_journalized gets registered
      VariableCostObject

      # TODO: this recreates the original behaviour
      # however, it might not be desirable to allow assigning of cost_object regardless of the permissions
      PermittedParams.permit(:new_work_package, :cost_object_id)

      require 'api/v3/work_packages/work_package_representer'

      API::V3::WorkPackages::WorkPackageRepresenter.to_eager_load += [:cost_object]

      # TODO: check default groups on types
      ##
      # Add a new group
      #cost_attributes = %i(cost_object)

      #constraint = ->(_type, project: nil) {
      #  project.nil? || project.costs_enabled?
      #}

      #cost_attributes.each do |attribute|
      #  ::Type.add_constraint attribute, constraint
      #end

      Queries::Register.filter Query, Queries::WorkPackages::Filter::CostObjectFilter
    end
  end
end
