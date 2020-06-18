#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Reporting
  class Engine < ::Rails::Engine
    engine_name :openproject_reporting

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-reporting',
             author_url: 'https://www.openproject.com',
             bundled: true do

      view_actions = [:index, :show, :drill_down, :available_values, :display_report_list]
      edit_actions = [:create, :update, :rename, :destroy]

      #register reporting_module including permissions
      project_module :reporting_module do
        permission :save_cost_reports, { cost_reports: edit_actions }
        permission :save_private_cost_reports, { cost_reports: edit_actions }
      end

      #register additional permissions for viewing time and cost entries through the CostReportsController
      view_actions.each do |action|
        OpenProject::AccessControl.permission(:view_time_entries).actions << "cost_reports/#{action}"
        OpenProject::AccessControl.permission(:view_own_time_entries).actions << "cost_reports/#{action}"
        OpenProject::AccessControl.permission(:view_cost_entries).actions << "cost_reports/#{action}"
        OpenProject::AccessControl.permission(:view_own_cost_entries).actions << "cost_reports/#{action}"
      end

      # register additional permissions for the work package costlog controller
      OpenProject::AccessControl.permission(:view_time_entries).actions << "work_package_costlog/index"
      OpenProject::AccessControl.permission(:view_own_time_entries).actions << "work_package_costlog/index"
      OpenProject::AccessControl.permission(:view_cost_entries).actions << "work_package_costlog/index"
      OpenProject::AccessControl.permission(:view_own_cost_entries).actions << "work_package_costlog/index"

      #menu extensions
      menu :top_menu,
           :cost_reports_global,
           { controller: '/cost_reports', action: 'index', project_id: nil },
           caption: :cost_reports_title,
           if: Proc.new {
             (User.current.logged? || !Setting.login_required?) &&
               (
               User.current.allowed_to?(:view_time_entries, nil, global: true) ||
                 User.current.allowed_to?(:view_own_time_entries, nil, global: true) ||
                 User.current.allowed_to?(:view_cost_entries, nil, global: true) ||
                 User.current.allowed_to?(:view_own_cost_entries, nil, global: true)
               )
           }

      menu :project_menu,
           :cost_reports,
           { controller: '/cost_reports', action: 'index' },
           param: :project_id,
           after: :time_entries,
           caption: :cost_reports_title,
           if: Proc.new { |project| project.module_enabled?(:reporting_module) },
           icon: 'icon2 icon-cost-reports'

      # Cost reports should remove the default time entries menu item
      hide_menu_item :project_menu,
                     :time_entries,
                     hide_if: -> (project) { project.module_enabled?(:reporting_module) }

      hide_menu_item :top_menu,
                     :time_sheet
    end

    initializer "reporting.register_hooks" do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/reporting/hooks'
    end

    initializer 'reporting.precompile_assets' do
      Rails.application.config.assets.precompile += %w(
        reporting_engine/reporting_engine.js
      )

      # Without this, tablesorter's assets are not found.
      # This should actually be done by rails itself when one adds the gem to the gemspec.
      Rails.application.config.assets.paths << Gem.loaded_specs['jquery-tablesorter'].full_gem_path + '/vendor/assets/javascripts'
    end

    config.to_prepare do
      require_dependency 'report/walker'
      require_dependency 'report/transformer'
      require_dependency 'widget/table/entry_table'
      require_dependency 'widget/settings_patch'
      require_dependency 'cost_query/group_by'
    end

    assets %w(reporting/reporting_styles.css
              reporting/reporting.js)

    patches %i[TimelogController CustomFieldsController OpenProject::Configuration]
    patch_with_namespace :BasicData, :RoleSeeder
    patch_with_namespace :BasicData, :SettingSeeder
  end
end
