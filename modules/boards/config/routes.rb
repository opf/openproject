Rails.application.routes.draw do
  resources :boards,
            controller: "boards/boards",
            only: %i[index new create],
            as: :work_package_boards

  scope "projects/:project_id", as: "project" do
    resources :boards,
              controller: "boards/boards",
              only: %i[index show new create destroy],
              as: :work_package_boards do
      collection do
        get "menu" => "boards/menus#show"
        get "kanban" => "boards/boards#kanban"
      end
      member do
        patch "set_default_kanban", action: :set_default_kanban
        get "details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: :overview },
            as: :details,
            work_package_split_view: true
      end
      get "(/*state)" => "boards/boards#show", on: :member, as: "", constraints: { id: /\d+/ }
    end
  end
end
