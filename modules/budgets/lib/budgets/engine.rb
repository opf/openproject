module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    register 'budgets',
             author_url: 'https://www.openproject.com',
             bundled: true,
             name: 'Budgets' do
      project_module :budgets do
        permission :view_budgets, { budgets: %i[index show] }
        permission :edit_budgets, { budgets: %i[index show edit update destroy new create copy] }
      end

      menu :project_menu,
           :budgets,
           { controller: '/budgets', action: 'index' },
           param: :project_id,
           before: :settings,
           caption: :budgets_title,
           icon: 'icon2 icon-budget'
    end

    activity_provider :budgets, class_name: 'Activities::BudgetActivityProvider', default: false

    #patches %i[Project User TimeEntry PermittedParams ProjectsController ApplicationHelper]
    #patch_with_namespace :WorkPackages, :BaseContract
    #patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    #patch_with_namespace :BasicData, :RoleSeeder
    #patch_with_namespace :BasicData, :SettingSeeder
    #patch_with_namespace :ActiveSupport, :NumberHelper, :NumberToCurrencyConverter

    add_api_path :budget do |id|
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

    initializer 'budgets.register_latest_project_activity' do
      Project.register_latest_project_activity on: 'Budget',
                                               attribute: :updated_at
    end

    config.to_prepare do
      # loading the class so that acts_as_journalized gets registered
      #Budget

      # TODO: check default groups on types
      ##
      # Add a new group
      #cost_attributes = %i(budget)

      #constraint = ->(_type, project: nil) {
      #  project.nil? || project.costs_enabled?
      #}

      #cost_attributes.each do |attribute|
      #  ::Type.add_constraint attribute, constraint
      #end

      Queries::Register.filter Query, Queries::WorkPackages::Filter::BudgetFilter
    end
  end
end
