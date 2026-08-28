# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    get "risk-log", to: "risk_management/risk_logs#index", as: :risk_log
    get "risk-log/plan", to: "risk_management/plans#show", as: :risk_management_plan
    get "risk-log/plan/edit", to: "risk_management/plans#edit", as: :edit_risk_management_plan
    patch "risk-log/plan", to: "risk_management/plans#update"
    get "risk-log/menu", to: "risk_management/menus#show", as: :risk_log_menu
    get "risk-log/details/:work_package_id(/:tab)",
        to: "risk_management/risk_logs#details",
        as: :risk_log_details,
        work_package_split_view: true,
        constraints: { work_package_id: WorkPackage::SemanticIdentifier::ID_ROUTE_CONSTRAINT },
        defaults: { tab: :overview }
  end

  namespace :risk_management do
    namespace :admin do
      resource :settings, only: %i[show update]
      resources :categories, except: :show
    end
  end
end
