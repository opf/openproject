Rails.application.routes.draw do
  scope :admin do
    namespace :saml do
      resources :providers do
        collection do
          post :import
        end
      end
    end
  end
end
