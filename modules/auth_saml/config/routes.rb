Rails.application.routes.draw do
  scope :admin do
    namespace :saml do
      resources :providers do
        member do
          post :import_metadata
          get :confirm_destroy
        end
      end
    end
  end
end
