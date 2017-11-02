module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    layout 'my'
    menu_item :avatar

    def show
      render 'avatars/my/avatar'
    end

    private

    def redirect_path
      edit_my_avatar_path
    end

    def set_user
      @user = current_user
    end
  end
end
