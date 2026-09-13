# frozen_string_literal: true

# Routes for CDE plugin
namespace :cde do
  resources :containers, only: %i[index show new create edit update destroy] do
    member do
      post :share
      post :publish
      post :archive
    end
  end
end

# API routes (handled in engine.rb)
