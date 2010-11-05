ActionController::Routing::Routes.draw do |map| 
  map.connect 'cost_entries/:id/edit', :action => 'edit', :controller => 'costlog'
  map.connect 'projects/:project_id/cost_entries/new', :action => 'edit', :controller => 'costlog'
  map.connect 'projects/:project_id/issues/:issue_id/cost_entries/new', :action => 'edit', :controller => 'costlog'
  
  map.with_options :controller => 'costlog' do |costlog|
    costlog.connect 'projects/:project_id/cost_entries', :action => 'details'
    
    costlog.with_options :action => 'details', :conditions => {:method => :get}  do |cost_details|
      cost_details.connect 'cost_entries'
      cost_details.connect 'cost_entries.:format'
      cost_details.connect 'issues/:issue_id/cost_entries'
      cost_details.connect 'issues/:issue_id/cost_entries.:format'
      cost_details.connect 'projects/:project_id/cost_entries.:format'
      cost_details.connect 'projects/:project_id/issues/:issue_id/cost_entries'
      cost_details.connect 'projects/:project_id/issues/:issue_id/cost_entries.:format'
    end
    
    costlog.with_options :action => 'edit', :conditions => {:method => :get} do |cost_edit|
      cost_edit.connect 'issues/:issue_id/cost_entries/new'
    end
      
    costlog.connect 'cost_entries/:id/destroy', :action => 'destroy', :conditions => {:method => :post}
  end
  
  map.with_options :controller => 'cost_objects' do |cost_objects|
    cost_objects.with_options :conditions => {:method => :get} do |co_views|
      co_views.connect 'cost_objects', :action => 'index'
      co_views.connect 'cost_objects.:format', :action => 'index'
      co_views.connect 'projects/:project_id/cost_objects', :action => 'index'
      co_views.connect 'projects/:project_id/cost_objects.:format', :action => 'index'
      
      co_views.connect 'projects/:project_id/cost_objects/new', :action => 'new'
      co_views.connect 'projects/:project_id/cost_objects/:copy_from/copy', :action => 'new'
      co_views.connect 'cost_objects/:id', :action => 'show', :id => /\d+/
      co_views.connect 'cost_objects/:id.:format', :action => 'show', :id => /\d+/
      co_views.connect 'cost_objects/:id/edit', :action => 'edit', :id => /\d+/
      co_views.connect 'cost_objects/:id/move', :action => 'move', :id => /\d+/
    end
    cost_objects.with_options :conditions => {:method => :post} do |co_actions|
      co_actions.connect 'projects/:project_id/cost_objects/:action', :action => /new|preview|update_(labor|material)_budget_item/
      co_actions.connect 'cost_objects/:id/:action', :action => /edit|move|destroy/, :id => /\d+/
    end
    cost_objects.connect 'cost_objects/:action'
  end
  
  map.with_options :controller => 'hourly_rates' do |hourly_rates|
    hourly_rates.with_options :conditions => {:method => :get} do |hr_views|
      hr_views.connect 'users/:id/default_rates', :action => 'show', :id => /\d+/
      hr_views.connect 'users/:id/default_rates/:action', :action => /edit/, :id => /\d+/

      hr_views.connect 'projects/:project_id/hourly_rates', :action => 'show'
      hr_views.connect 'projects/:project_id/hourly_rates/:id', :action => 'show', :id => /\d+/
      hr_views.connect 'projects/:project_id/hourly_rates/:id/:action', :action => /edit/, :id => /\d+/
    end
    hourly_rates.with_options :conditions => {:method => :post} do |hr_actions|
      hr_actions.connect 'users/:id/default_rates/:action', :action => 'edit', :id => /\d+/
      hr_actions.connect 'projects/:project_id/hourly_rates/:id/:action', :action => /edit/, :id => /\d+/
    end
  end
  
  map.connect 'projects/:project_id/costlog/:action/:id', :controller => 'costlog', :project_id => /.+/

#  map.connect 'projects/:project_id/hourly_rates/:action/:id', :controller => 'hourly_rates', :project_id => /.+/
end
