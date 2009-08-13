require 'redmine'

# Patches to the Redmine core.
require 'dispatcher'
require 'issue_patch'
require 'project_patch'
Dispatcher.to_prepare do
  Issue.send(:include, IssuePatch)
  Issue.send(:include, ProjectPatch)
end

# Hooks
require_dependency 'costs_issue_hook'

# monkey patches
require_dependency 'l10n_patch'


Redmine::Plugin.register :redmine_costs do
  name 'Costs Plugin'
  author 'Holger Just'
  author_url 'http://finn.de/team'
  description 'The costs plugin provides basic cost management functionality for Redmine.'
  version '0.0.1'
  
  requires_redmine :version_or_higher => '0.8.4'
  
  settings :default => {
    'costs_currency' => 'EUR',
    'costs_currency_format' => '%n %u'
  }, :partial => 'settings/settings'

  
  project_module :costs_module do
    # from controlling requirements 3.5 (3)
    permission :view_own_rate, {}
    permission :view_all_rates, {}
    permission :change_rates, {}
  
    # from controlling requirements 4.5
    permission :view_unit_price, {:deliverables => [:index]}
    permission :book_own_costs, {:costlog => :edit}, :require => :loggedin
    permission :book_costs, {:costlog => :edit}, :require => :member
    permission :edit_own_cost_entries, {:costlog => [:edit, :destroy]}, :require => :loggedin
    permission :edit_cost_entries, {:costlog => [:edit, :destroy]}, :require => :member
    permission :view_cost_entries, {:costlog => [:details]}
    permission :block_tickets, {}, :require => :member
    
    permission :view_deliverables, {:deliverables => [:index, :show, :edit]}
    permission :edit_deliverables, {:deliverables => [:edit, :destroy, :new]}
  end
  
  # Menu extensions
  menu :project_menu, :deliverables, {:controller => 'deliverables', :action => 'index'}, \
    :param => :project_id, :after => :new_issue, :caption => :deliverables_title
  menu :top_menu, :costs, {:controller => 'costs', :action => 'index'}, \
    :caption => :costs_title
  
  # Activities
  activity_provider :deliverables
end