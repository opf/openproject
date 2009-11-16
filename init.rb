require 'redmine'

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
  Role.send(:include, RolePatch)
  TimeEntry.send(:include, TimeEntryPatch)
  Query.send(:include, QueryPatch)
  UsersHelper.send(:include, CostsUsersHelperPatch)
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
    
    a = {
    :view_own_rate => :view_own_hourly_rate,
    :view_all_rates => :view_hourly_rates,
    :change_rates => :edit_hourly_rates,
    
    :view_unit_price => :view_cost_rates,
    :book_own_costs => :log_own_costs,
    :book_costs => :log_costs
    }
    
    # from controlling requirements 3.5 (3)
    permission :view_own_hourly_rate, {}
    permission :view_hourly_rates, {:cost_reports => :index}
    permission :edit_hourly_rates, {:hourly_rates => [:set_rate, :edit]}

    # from controlling requirements 4.5
    permission :view_cost_rates, {:cost_reports => :index}
    permission :book_own_costs, {:costlog => :edit}, :require => :loggedin
    permission :book_costs, {:costlog => :edit}, :require => :member
    permission :edit_own_cost_entries, {:costlog => [:edit, :destroy]}, :require => :loggedin
    permission :edit_cost_entries, {:costlog => [:edit, :destroy]}, :require => :member
    permission :view_own_cost_entries, {:costlog => [:details]}
    permission :view_cost_entries, {:costlog => [:details]}
    permission :block_tickets, {}, :require => :member

    permission :view_cost_objects, {:cost_objects => [:index, :show]}
    permission :edit_cost_objects, {:cost_objects => [:index, :show, :edit, :destroy, :new]}
  end
  
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

