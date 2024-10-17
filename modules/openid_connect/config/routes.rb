Rails.application.routes.draw do
  get "/session/logout_warning", to: "session#logout_warning"

  scope :admin do
    namespace :openid_connect do
      resources :providers, except: %i[show] do
        get :confirm_destroy, on: :member
      end
    end
  end
end
