require 'redmine'

# Hooks
require 'view_projects_show_sidebar_bottom_hook'

Redmine::Plugin.register :redmine_reporting do
  name 'Reporting Plugin'
  author 'Konstantin Haase, Philipp Tessenow @ finnlabs'
  author_url 'http://finn.de/team'
  description 'The reporting plugin provides extended reporting functionality for Redmine including Cost Reports.'
  version '1.0.6'

  requires_redmine :version_or_higher => '0.9'
  requires_redmine_plugin :redmine_costs, :version_or_higher => '0.3'

  #register reporting_module including permissions
  project_module :reporting_module do
    #require_or_load 'costs_access_control_permission_patch'

    permission :view_cost_entries, {:costlog => [:details], :cost_reports => [:index, :drill_down]}
    permission :view_own_cost_entries, {:costlog => [:details], :cost_reports => [:index, :drill_down]},
      :granular_for => :view_cost_entries
  end

  #register additional permissions for the time log
  Redmine::AccessControl.permission(:view_own_time_entries).actions << "cost_reports/index"

  #menu extensions
  menu :top_menu, :cost_reports_global, {:controller => 'cost_reports', :action => 'index', :project_id => nil},
    :caption => :cost_reports_title,
    :if => Proc.new {
      ( User.current.allowed_to?(:view_cost_entries, nil, :global => true, :for => User.current ) ||
        User.current.allowed_to?(:view_time_entries, nil, :global => true, :for => User.current )
      )
    }

  menu :project_menu, :cost_reports, {:controller => 'cost_reports', :action => 'index'},
    :param => :project_id, :after => :cost_objects, :caption => :cost_reports_title
end

