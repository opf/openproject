ActionController::Routing::Routes.draw do |map| 
  map.connect 'projects/:project_id/costlog/:action/:id', :controller => 'costlog', :project_id => /.+/
  map.connect 'projects/:project_id/cost_reports/:action/:id', :controller => 'cost_reports', :project_id => /.+/
  map.connect 'projects/:project_id/cost_objects/:action/:id', :controller => 'cost_objects'
  map.connect 'projects/:project_id/hourly_rates/:action/:id', :controller => 'hourly_rates', :project_id => /.+/
end
