OpenProject::Application.routes.draw do

  scope module: 'avatars' do
    # Update my avatar
    scope 'my' do
      resource :avatar, controller: 'my_avatar', as: 'edit_my_avatar', only: %i[show update destroy]
    end

    # Get the current avatar
    get '/users/:id/avatar', controller: 'avatar', action: :show, as: 'user_avatar'

    # Update another user's avatar
    resources :users do
      member do
        resource :avatar, controller: 'users', as: 'edit_user_avatar', only: %i[show update destroy]
      end
    end
  end
end
