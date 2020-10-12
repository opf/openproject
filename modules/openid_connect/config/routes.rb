Rails.application.routes.draw do
  get '/session/logout_warning', to: 'session#logout_warning'

  scope :admin do
    namespace :openid_connect do
      resources :providers, only: [:index, :new, :create, :edit, :update, :destroy]
    end
  end
end
