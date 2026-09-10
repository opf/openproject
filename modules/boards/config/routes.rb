Rails.application.routes.draw do
  extend Routing::Helpers::ProjectScope

  resources :boards,
            controller: "boards/boards",
            only: %i[index new create],
            as: :work_package_boards

  project_scope do
    resources :boards,
              controller: "boards/boards",
              only: %i[index show new create destroy],
              as: :work_package_boards do
      collection do
        get "menu" => "boards/menus#show"
      end
      member do
        get "details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: :overview },
            as: :details,
            work_package_split_view: true
      end
    end
  end
end
