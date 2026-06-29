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

module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    register "budgets",
             author_url: "https://www.openproject.org",
             bundled: true do
      project_module :budgets do
        permission :view_budgets,
                   { budgets: %i[index show] },
                   permissible_on: :project
        permission :edit_budgets,
                   {
                     budgets: %i[index show edit update destroy destroy_info new create copy]
                   },
                   permissible_on: :project,
                   dependencies: :view_budgets
      end

      menu :project_menu,
           :budgets,
           { controller: "/budgets", action: "index" },
           if: ->(project) { project.module_enabled?(:budgets) },
           after: :costs,
           caption: :budgets_title,
           icon: "op-budget"
    end

    patch_with_namespace :Projects, :RowComponent
    patch_with_namespace :Portfolios, :DetailsComponent

    add_api_path :budget do |id|
      "#{root}/budgets/#{id}"
    end

    add_api_path :budgets_by_project do |project_id|
      "#{project(project_id)}/budgets"
    end

    add_api_path :attachments_by_budget do |id|
      "#{budget(id)}/attachments"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Budgets::BudgetsAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::Budgets::BudgetsByProjectAPI
    end

    config.to_prepare do
      Budgets::Hooks::WorkPackageHook
    end

    config.to_prepare do
      ::Exports::Register.register do
        formatter Project, Projects::Exports::Formatters::BudgetCurrencyAttribute
        formatter Project, Projects::Exports::Formatters::BudgetSpentRatio
      end

      OpenProject::ProjectLatestActivity.register on: "Budget"

      # Add to the budget to the costs group
      ::Type.add_default_mapping(:costs, :budget)

      ::Type.add_constraint :budget, ->(_type, project: nil) {
        project.nil? || project.module_enabled?(:budgets)
      }

      ::Queries::Register.register(::Query) do
        filter Queries::WorkPackages::Filter::BudgetFilter
      end

      ::Queries::Register.register(::ProjectQuery) do
        select Queries::Projects::Selects::BudgetPlanned
        select Queries::Projects::Selects::BudgetSpent
        select Queries::Projects::Selects::BudgetSpentRatio
        select Queries::Projects::Selects::BudgetAvailable
      end
    end
  end
end
