Rails.application.routes.draw do
  scope "projects/:project_id", as: "project" do
    resources :calendars,
              controller: "calendar/calendars",
              only: %i[index show new create destroy],
              as: :calendars do
      collection do
        get "menu" => "calendar/menus#show"
        get "new/details/new",
            action: :split_create,
            work_package_split_create: true
        get "new/details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: :overview },
            work_package_split_view: true
      end
      get "/ical" => "calendar/ical#show", on: :member, as: "ical"
      member do
        get "details/new",
            action: :split_create,
            as: :split_create,
            work_package_split_create: true
        get "details/:work_package_id(/:tab)",
            action: :split_view,
            defaults: { tab: :overview },
            as: :details,
            work_package_split_view: true
      end
    end
  end

  resources :calendars, only: %i[index new create], controller: "calendar/calendars"
end
