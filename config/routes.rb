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
  end
  
  map.connect 'projects/:project_id/cost_reports/:action/:id', :controller => 'cost_reports', :project_id => /.+/
  map.connect 'projects/:project_id/cost_objects/:action/:id', :controller => 'cost_objects'
  map.connect 'projects/:project_id/hourly_rates/:action/:id', :controller => 'hourly_rates', :project_id => /.+/
end
