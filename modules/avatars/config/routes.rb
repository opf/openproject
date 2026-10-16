Rails.application.routes.draw do
  # Update my avatar
  scope "my" do
    resource :avatar, controller: "avatars/my_avatar", as: "edit_my_avatar", only: %i[show destroy] do
      member do
        patch :update_settings
      end
    end
  end

  # Get the current avatar
  get "/users/:id/avatar", controller: "avatars/avatar", action: :show, as: "user_avatar"

  # Update another user's avatar
  scope "users/:id" do
    resource :avatar, controller: "avatars/users", as: "edit_user_avatar", only: %i[show destroy] do
      member do
        patch :update_settings
      end
    end
  end

  # Update a group's avatar
  scope "groups/:id" do
    resource :avatar, controller: "avatars/groups", as: "edit_group_avatar", only: %i[destroy] do
      member do
        patch :update_settings
      end
    end
  end
end
