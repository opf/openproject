Rails.application.routes.draw do
  # Update my avatar
  scope "my" do
    resource :avatar, controller: "avatars/my_avatar", as: "edit_my_avatar", only: %i[update destroy] do
      member do
        patch :update_color
      end
    end
  end

  # Get the current avatar
  get "/users/:id/avatar", controller: "avatars/avatar", action: :show, as: "user_avatar"

  # Update another user's avatar
  scope "users/:id" do
    resource :avatar, controller: "avatars/users", as: "edit_user_avatar", only: %i[show update destroy] do
      member do
        patch :update_color
      end
    end
  end
end
