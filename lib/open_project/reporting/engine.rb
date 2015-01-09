#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
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

module OpenProject::Reporting
  class Engine < ::Rails::Engine
    engine_name :openproject_reporting

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-reporting',
             author_url: 'http://finn.de',
             requires_openproject: '>= 4.0.0' do

    view_actions = [:index, :show, :drill_down, :available_values, :display_report_list]
    edit_actions = [:create, :update, :rename, :delete]

    #register reporting_module including permissions
    project_module :reporting_module do
      permission :save_cost_reports, {cost_reports: edit_actions}
      permission :save_private_cost_reports, {cost_reports: edit_actions}
    end

    #register additional permissions for viewing time and cost entries through the CostReportsController
    view_actions.each do |action|
      Redmine::AccessControl.permission(:view_time_entries).actions << "cost_reports/#{action}"
      Redmine::AccessControl.permission(:view_own_time_entries).actions << "cost_reports/#{action}"
      Redmine::AccessControl.permission(:view_cost_entries).actions << "cost_reports/#{action}"
      Redmine::AccessControl.permission(:view_own_cost_entries).actions << "cost_reports/#{action}"
    end

    #menu extensions
    menu :top_menu, :cost_reports_global, {controller: 'cost_reports', action: 'index', project_id: nil},
      caption: :cost_reports_title,
      if: Proc.new {
        ( User.current.allowed_to?(:view_time_entries, nil, global: true) ||
          User.current.allowed_to?(:view_own_time_entries, nil, global: true) ||
          User.current.allowed_to?(:view_cost_entries, nil, global: true) ||
          User.current.allowed_to?(:view_own_cost_entries, nil, global: true)
        )
      }

    menu :project_menu, :cost_reports,
         {controller: 'cost_reports', action: 'index'},
         param: :project_id,
         after: :cost_objects,
         caption: :cost_reports_title,
         if: Proc.new { |project| project.module_enabled?(:reporting_module) },
         html: {class: 'icon2 icon-stats'}
    end

    initializer "reporting.register_hooks" do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/reporting/hooks'
    end

    initializer 'reporting.precompile_assets' do
      Rails.application.config.assets.precompile += %w(
        reporting_engine/reporting_engine.css
        reporting_engine/reporting_engine.js
      )
    end

    config.to_prepare do
      require_dependency 'report/walker'
      require_dependency 'report/transformer'
      require_dependency 'widget/sortable_init'
      require_dependency 'widget/simple_table'
      require_dependency 'widget/entry_table'
      require_dependency 'widget/settings_patch'
      require_dependency 'cost_query/group_by'
    end

    patches [:CostlogController, :TimelogController, :CustomFieldsController]
  end
end
