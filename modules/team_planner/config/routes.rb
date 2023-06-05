OpenProject::Application.routes.draw do
  get :team_planners, to: 'team_planner/team_planner#overview'

  scope 'projects/:project_id', as: 'project' do
    resources :team_planners,
              controller: 'team_planner/team_planner',
              only: %i[index destroy],
              as: :team_planners do
      get :upsale, to: 'team_planner/team_planner#upsale', on: :collection, as: :upsale

      get '/new' => 'team_planner/team_planner#show', on: :collection, as: 'new'
      get '(/*state)' => 'team_planner/team_planner#show', on: :member, as: ''
    end
  end
end
