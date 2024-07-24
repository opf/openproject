Rails.application.routes.draw do
  scope :admin do
    namespace :saml do
      resources :providers, only: %i[index new create edit update destroy] do
        collection do
          post :import
        end
      end
    end
  end
end
