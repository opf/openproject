module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    layout "my"
    menu_item :avatar

    no_authorization_required! :show,
                               :update_settings,
                               :destroy

    def show; end

    private

    def redirect_path
      edit_my_avatar_path
    end

    def set_user
      @principal = current_user
    end
  end
end
