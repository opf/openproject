require 'redmine'

# begin
#   require 'rubygems'
#   require 'composite_primary_keys'
# rescue LoadError
#   raise Exception.new("ERROR: Please install Composite Primary Keys gem via \"gem install composite_primary_keys\"")
# end
#
unless defined? GLoc
  module ::GLoc
    def l(*args)
      I18n.t(*args)
    end
  end
end


require 'costs_i18n_patch'

require 'dispatcher'

Dispatcher.to_prepare do
  # Model Patches
  require_dependency 'costs_group_patch'
  require_dependency 'costs_issue_patch'
  require_dependency 'costs_project_patch'
  require_dependency 'costs_role_patch'
  require_dependency 'costs_query_patch'
  require_dependency 'costs_user_patch'
  require_dependency 'costs_time_entry_patch'
  require_dependency 'costs_version_patch'

  # Controller Patches
  require_dependency 'costs_application_controller_patch'
  require_dependency 'costs_groups_controller_patch'
  require_dependency 'costs_issues_controller_patch'
  require_dependency 'costs_timelog_controller_patch'

  # Helper Patches
  require_dependency 'costs_application_helper_patch'
  require_dependency 'costs_users_helper_patch'
  require_dependency 'costs_issues_helper_patch'

  # Library Patches
  require_or_load 'costs_access_control_permission_patch'
  require_dependency 'costs_access_control_patch'

  require_dependency 'costs_issue_observer'

end

# Hooks
require 'costs_issue_hook'
require 'costs_project_hook'

Redmine::Plugin.register :redmine_costs do

  name 'Costs Plugin'
  author 'Holger Just @ finnlabs'
  author_url 'http://finn.de/team#h.just'
  description 'The costs plugin provides basic cost management functionality for Redmine.'
  version '2.0.0'

  requires_redmine :version_or_higher => '0.9'

  settings :default => {
    'costs_currency' => 'EUR',
    'costs_currency_format' => '%n %u'
  }, :partial => 'settings/redmine_costs'


  # register our custom permissions
  project_module :costs_module do
    require_or_load 'costs_access_control_permission_patch'

    permission :view_own_hourly_rate, {},
      :granular_for => :view_hourly_rates
    permission :view_hourly_rates, {}
    permission :edit_own_hourly_rate, {:hourly_rates => [:set_rate, :edit]},
      :require => :member,
      :granular_for => :edit_hourly_rate,
      :inherits => :view_own_hourly_rate
    permission :edit_hourly_rates, {:hourly_rates => [:set_rate, :edit]},
      :require => :member,
      :inherits => :view_hourly_rates

    permission :view_cost_rates, {}
    permission :log_own_costs, {:costlog => :edit},
      :require => :loggedin,
      :granular_for => :log_costs
    permission :log_costs, {:costlog => :edit},
      :require => :member
    permission :edit_own_cost_entries, {:costlog => [:edit, :destroy]},
      :require => :loggedin,
      :granular_for => :edit_cost_entries,
      :inherits => :view_own_cost_entries
    permission :edit_cost_entries, {:costlog => [:edit, :destroy]},
      :require => :member,
      :inherits => :view_cost_entries
    permission :block_tickets, {}, :require => :member

    permission :view_cost_objects, {:cost_objects => [:index, :show]},
      :inherits => [:view_cost_entries, :view_time_entries, :view_cost_rates, :view_hourly_rates]
    permission :edit_cost_objects, {:cost_objects => [:index, :show, :edit, :destroy, :new]},
      :inherits => :view_cost_objects
  end

  # register additional permissions for the time log
  project_module :time_tracking do
    permission :view_own_time_entries, {:timelog => [:details, :report]}, :granular_for => :view_time_entries
  end

  view_time_entries = Redmine::AccessControl.permission(:view_time_entries)
  view_time_entries.instance_variable_set("@inherits", [:view_own_time_entries])
  view_time_entries.actions << "cost_reports/index"

  edit_time_entries = Redmine::AccessControl.permission(:edit_time_entries)
  edit_time_entries.instance_variable_set("@inherits", [:view_time_entries])

  edit_own_time_entries = Redmine::AccessControl.permission(:edit_own_time_entries)
  edit_own_time_entries.instance_variable_set("@inherits", [:view_own_time_entries])
  edit_own_time_entries.instance_variable_set("@granular_for", :edit_time_entries)

  # Menu extensions
  menu :top_menu, :cost_types, {:controller => 'cost_types', :action => 'index'},
    :caption => :cost_types_title, :if => Proc.new { User.current.admin? }

  menu :project_menu, :cost_objects, {:controller => 'cost_objects', :action => 'index'},
    :param => :project_id, :before => :settings, :caption => :cost_objects_title

  # Activities
  activity_provider :cost_objects
end

# Observers
ActiveRecord::Base.observers.push :rate_observer, :default_hourly_rate_observer#, :costs_issue_observer

