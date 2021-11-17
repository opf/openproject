OpenProject::Application.routes.draw do
  #scope 'projects/:project_id', as: 'project' do
  #  get '/team_planner(/*state)', to: 'team_planner/team_planner#index'
  #end
  get '/projects/:project_id/team_planner', to: 'team_planner/team_planner#index'
end
