module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    register 'budgets',
             author_url: 'https://www.openproject.org',
             bundled: true,
             name: 'Budgets' do
      project_module :budgets do
        permission :view_budgets, { budgets: %i[index show] }
        permission :edit_budgets, { budgets: %i[index show edit update destroy destroy_info new create copy] }
      end

      menu :project_menu,
           :budgets,
           { controller: '/budgets', action: 'index' },
           param: :project_id,
           if: ->(project) { project.module_enabled?(:budgets) },
           after: :costs,
           caption: :budgets_title,
           icon: 'icon2 icon-budget'
    end

    activity_provider :budgets, class_name: 'Activities::BudgetActivityProvider', default: false

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

    initializer 'budgets.register_hooks' do
      # TODO: avoid hooks as this is part of the core now
      require 'budgets/hooks/work_package_hook'
    end

    config.to_prepare do
      # Add to the budget to the costs group
      ::Type.add_default_mapping(:costs, :budget)

      ::Type.add_constraint :budget, ->(_type, project: nil) {
        project.nil? || project.module_enabled?(:budgets)
      }

      Queries::Register.filter Query, Queries::WorkPackages::Filter::BudgetFilter
    end
  end
end
