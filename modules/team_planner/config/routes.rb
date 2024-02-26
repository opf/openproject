Rails.application.routes.draw do
  resources :team_planners,
            controller: 'team_planner/team_planner',
            only: %i[create] do
    collection do
      get '/', to: 'team_planner/team_planner#overview'
      get '/new', to: 'team_planner/team_planner#new'
      get '/upsale', to: 'team_planner/team_planner#upsale', as: :upsale
    end
  end

  scope 'projects/:project_id', as: 'project' do
    resources :team_planners,
              controller: 'team_planner/team_planner',
              only: %i[index destroy],
              as: :team_planners do
      collection do
        get '/upsale', to: 'team_planner/team_planner#upsale', as: :upsale
        get '/new', to: 'team_planner/team_planner#show', as: :new
      end

      member do
        get '(/*state)' => 'team_planner/team_planner#show', as: ''
      end
    end
  end
end
