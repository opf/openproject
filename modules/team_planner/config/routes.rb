OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :team_planners,
              controller: 'team_planner/team_planner',
              only: %i[index destroy],
              as: :team_planners do

      get '/new' => 'team_planner/team_planner#show', on: :collection, as: 'new'
      get '(/*state)' => 'team_planner/team_planner#show', on: :member, as: ''
    end
  end
end
