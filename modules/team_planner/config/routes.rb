Rails.application.routes.draw do
  resources :team_planners,
            controller: "team_planner/team_planner",
            only: %i[create] do
    collection do
      get "/", to: "team_planner/team_planner#overview"
      get "/new", to: "team_planner/team_planner#new"
    end
  end

  scope "projects/:project_id", as: "project" do
    resources :team_planners,
              controller: "team_planner/team_planner",
              only: %i[index destroy show],
              as: :team_planners do
      collection do
        get "menu" => "team_planner/menus#show"
        get "new/details/new",
            action: :split_create,
            work_package_split_create: true
        get "new/details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: "overview" },
            work_package_split_view: true
        get "/new", to: "team_planner/team_planner#show", as: :new
      end

      member do
        get "details/new",
            action: :split_create,
            as: :split_create,
            work_package_split_create: true
        get "details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: "overview" },
            as: :details,
            work_package_split_view: true
      end
    end
  end
end
