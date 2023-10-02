Rails.application.routes.draw do
  scope :admin do
    namespace :saml do
      resources :providers, only: %i[index new create edit update destroy]
    end
  end
end
