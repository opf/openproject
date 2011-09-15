ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:project_id/cost_reports.:format', :controller => 'cost_reports', :project_id => /.+/, :action => 'index'
  map.connect 'projects/:project_id/cost_reports/:action/:id', :controller => 'cost_reports', :project_id => /.+/
end
