Rails.application.routes.draw do
  scope "projects/:project_id", as: "project" do
    resources :gantt, controller: "gantt/gantt", only: [:index] do
      collection do
        # The menu route has to be above the state routes! Otherwise, the menu will be interpreted as another state
        get "menu" => "gantt/menus#show"
        get "/export_dialog" => "work_packages#export_dialog"

        get "details/:work_package_id(/:tab)" => "gantt/gantt#split_view", as: :details,
            defaults: { tab: "overview" }, work_package_split_view: true,
            constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT }

        get "/create_new" => "gantt/gantt#split_create", as: "new_split", work_package_split_create: true
      end
    end
  end

  resources :gantt, controller: "gantt/gantt", only: [:index] do
    collection do
      get "/export_dialog" => "work_packages#export_dialog"

      get "details/:work_package_id(/:tab)" => "gantt/gantt#split_view", as: :details,
          defaults: { tab: "overview" }, work_package_split_view: true,
          constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT }

      get "/create_new" => "gantt/gantt#split_create", as: "new_split", work_package_split_create: true

      get "/" => "gantt/gantt#index", as: "index"
    end
  end

  namespace :gantt do
    resource :menu, only: %[show]
  end
end
