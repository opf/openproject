require 'redmine'

# Hooks
require 'view_projects_show_sidebar_bottom_hook'
$LOAD_PATH << File.expand_path("../lib/redmine_widgets", __FILE__)
require 'simple_table'
require 'entry_table'
require 'cost_types'
require 'settings'

Redmine::Plugin.register :redmine_reporting do
  name 'Reporting Plugin'
  author 'Konstantin Haase, Philipp Tessenow @ finnlabs'
  author_url 'http://finn.de/team'
  description 'The reporting plugin provides extended reporting functionality for Redmine including Cost Reports.'
  version '3.0.0'

  requires_redmine :version_or_higher => '0.9'
  requires_redmine_plugin :redmine_costs, :version_or_higher => '4.0'

  view_actions = [:index, :show, :drill_down, :available_values, :display_report_list]
  edit_actions = [:create, :update, :rename, :delete]

  #register reporting_module including permissions
  project_module :reporting_module do
    permission :save_cost_reports, {:cost_reports => edit_actions}
    permission :save_private_cost_reports, {:cost_reports => edit_actions}
  end

  #register additional permissions for the time log
  view_actions.each do |action|
    Redmine::AccessControl.permission(:view_time_entries).actions << "cost_reports/#{action}"
    Redmine::AccessControl.permission(:view_own_time_entries).actions << "cost_reports/#{action}"
    Redmine::AccessControl.permission(:view_cost_entries).actions << "cost_reports/#{action}"
    Redmine::AccessControl.permission(:view_own_cost_entries).actions << "cost_reports/#{action}"
  end

  [:details].each do |action|
    Redmine::AccessControl.permission(:view_cost_entries).actions << "costlog/#{action}"
    Redmine::AccessControl.permission(:view_own_cost_entries).actions << "costlog/#{action}"
  end

  #menu extensions
  menu :top_menu, :cost_reports_global, {:controller => 'cost_reports', :action => 'index', :project_id => nil},
    :caption => :cost_reports_title,
    :if => Proc.new {
      ( User.current.allowed_to?(:view_time_entries, nil, :global => true) ||
        User.current.allowed_to?(:view_own_time_entries, nil, :global => true) ||
        User.current.allowed_to?(:view_cost_entries, nil, :global => true) ||
        User.current.allowed_to?(:view_own_cost_entries, nil, :global => true)
      )
    }

  menu :project_menu, :cost_reports,
       {:controller => 'cost_reports', :action => 'index'},
       :param => :project_id,
       :after => :cost_objects,
       :caption => :cost_reports_title,
       :if => Proc.new { |project| project.module_enabled?(:reporting_module) }
end
