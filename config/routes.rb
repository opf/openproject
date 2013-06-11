OpenProject::Application.routes.draw do
  scope 'projects/:project_id' do
    match  'projects/:project_id/cost_reports.:format', :controller => 'cost_reports', :project_id => /.+/, :action => 'index'
    match 'projects/:project_id/cost_reports/:action/:id', :controller => 'cost_reports', :project_id => /.+/
  end
end
