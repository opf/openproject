OpenProject::Application.routes.draw do
  get '/projects/:project_id/dashboards', to: 'dashboards/dashboards#show', as: :project_dashboards
end
