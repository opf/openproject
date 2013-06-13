OpenProject::Application.routes.draw do
  match 'projects/:project_id/cost_reports', :controller => 'cost_reports', :project_id => /.+/, :action => 'index'
  match 'projects/:project_id/cost_reports/:action/:id', :controller => 'cost_reports', :project_id => /.+/
end
