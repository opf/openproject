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

# Patches to the Redmine core.
require_dependency 'l10n_patch'

require 'dispatcher'

Dispatcher.to_prepare do
  Issue.send(:include, IssuePatch)
  Project.send(:include, ProjectPatch)
  User.send(:include, UserPatch)
  Group.send(:include, GroupPatch)
  Role.send(:include, RolePatch)
  TimeEntry.send(:include, TimeEntryPatch)
  Query.send(:include, QueryPatch)
  UsersHelper.send(:include, CostsUsersHelperPatch)

  ApplicationController.send(:include, ApplicationControllerPatch)
  GroupsController.send(:include, GroupsControllerPatch)
  
  Redmine::AccessControl::Permission.send(:include, AccessControlPermissionPatch)
  Redmine::AccessControl.send(:include, AccessControlPatch)
end

# Hooks
require 'costs_issue_hook'
require 'costs_project_hook'

Redmine::Plugin.register :redmine_costs do

  name 'Costs Plugin'
  author 'Holger Just @ finnlabs'
  author_url 'http://finn.de/team#h.just'
  description 'The costs plugin provides basic cost management functionality for Redmine.'
  version '0.3'
  
  requires_redmine :version_or_higher => '0.8'
  
  settings :default => {
    'costs_currency' => 'EUR',
    'costs_currency_format' => '%n %u'
  }, :partial => 'settings/redmine_costs'

  
  # register our custom permissions
  project_module :costs_module do
    
    # rename_schema = {
    # :view_own_rate => :view_own_hourly_rate,
    # :view_all_rates => :view_hourly_rates,
    # :change_rates => :edit_hourly_rates,
    # 
    # :view_unit_price => :view_cost_rates,
    # :book_own_costs => :log_own_costs,
    # :book_costs => :log_costs
    # }
    
    
    # @@permission_tree = {
    #   :view_own_time_entries => [:view_time_entries, :edit_own_time_entries], 
    #   :view_time_entries => [:edit_time_entries, :view_cost_objects],
    #   :edit_own_time_entries => :edit_time_entries,
    # 
    #   :log_own_time => :log_time,
    #   :log_own_costs => :log_costs,
    # 
    #   :view_own_hourly_rates => [:view_hourly_rates, :edit_own_hourly_rate],
    #   :view_hourly_rates => [:edit_hourly_rates, :view_cost_objects],
    #   :edit_own_hourly_rate => :edit_hourly_rates,
    # 
    #   :view_own_cost_entries => [:view_cost_entries, :edit_own_cost_entries],
    #   :view_cost_entries => [:edit_cost_entries, :view_cost_objects],
    #   :edit_own_cost_entries => :edit_cost_entries,
    # 
    #   :view_cost_rates => :view_cost_objects,
    # 
    #   :view_cost_objects => :edit_cost_objects,
    # }
    
    # from controlling requirements 3.5 (3)

    Redmine::AccessControl::Permission.send(:include, AccessControlPermissionPatch)

    permission :view_own_hourly_rate, {},
      :granular_for => :view_hourly_rate

    permission :view_hourly_rates, {:cost_reports => :index}
    permission :edit_own_hourly_rate, {:hourly_rates => [:set_rate, :edit]},
      :require => :member,
      :granular_for => :edit_hourly_rate,
      :inherits => :view_own_hourly_rate
    permission :edit_hourly_rates, {:hourly_rates => [:set_rate, :edit]},
      :require => :member,
      :inherits => :view_hourly_rates

    # from controlling requirements 4.5
    permission :view_cost_rates, {:cost_reports => :index}
    permission :book_own_costs, {:costlog => :edit},
      :require => :loggedin,
      :granular_for => :book_costs
    permission :book_costs, {:costlog => :edit},
      :require => :member
    permission :edit_own_cost_entries, {:costlog => [:edit, :destroy]},
      :require => :loggedin,
      :granular_for => :edit_cost_entries,
      :inherits => :view_own_cost_entries
    permission :edit_cost_entries, {:costlog => [:edit, :destroy]},
      :require => :member,
      :inherits => :view_cost_entries
    permission :view_own_cost_entries, {:costlog => [:details]},
      :granular_for => :view_cost_entries
    permission :view_cost_entries, {:costlog => [:details]}
    permission :block_tickets, {}, :require => :member

    permission :view_cost_objects, {:cost_objects => [:index, :show]}
    permission :edit_cost_objects, {:cost_objects => [:index, :show, :edit, :destroy, :new]},
      :inherits => :view_cost_objects
  end
  
  # register additional permissions for the time log
  project_module :time_tracking do
    permission :view_own_time_entries, {:timelog => [:details, :report]},
      :granular_for => :view_time_entries
  end
  
  edit_time_entries = Redmine::AccessControl.permission(:edit_time_entries)
  edit_time_entries.instance_variable_set("@inherits", [:view_time_entries])

  edit_own_time_entries = Redmine::AccessControl.permission(:edit_own_time_entries)
  edit_own_time_entries.instance_variable_set("@inherits", [:view_own_time_entries])
  edit_own_time_entries.instance_variable_set("@granular_for", :edit_time_entries)

  # Menu extensions
  menu :top_menu, :cost_types, {:controller => 'cost_types', :action => 'index'},
    :caption => :cost_types_title, :if => Proc.new { User.current.admin? }
#  menu :top_menu, :cost_reports, {:controller => 'cost_reports', :action => 'index'},
#    :caption => :cost_reports_title,
#    :if => Proc.new {
#      ( User.current.allowed_to?(:view_cost_objects, nil, :global => true) ||
#        User.current.allowed_to?(:edit_cost_objects, nil, :global => true)
#      )
#    }

  menu :project_menu, :cost_objects, {:controller => 'cost_objects', :action => 'index'},
    :param => :project_id, :after => :new_issue, :caption => :cost_objects_title

  menu :project_menu, :cost_reports, {:controller => 'cost_reports', :action => 'index'},
    :param => :project_id, :after => :cost_objects, :caption => :cost_reports_title
  
  # Activities
  activity_provider :cost_objects
end

# Observers
ActiveRecord::Base.observers = :rate_observer, :default_hourly_rate_observer

