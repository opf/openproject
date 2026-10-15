module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    layout "my"
    menu_item :avatar

    no_authorization_required! :show,
                               :image,
                               :update_settings,
                               :update,
                               :destroy,
                               :update_color,
                               :update_text

    def show; end

    private

    def redirect_path
      edit_my_avatar_path
    end

    def set_user
      @principal = current_user
    end

    def update_color_request
      ::Users::UpdateService
        .new(model: @principal, user: current_user)
        .call(pref: { avatar_color: params[:avatar_color] })
    end

    def update_text_request
      ::Users::UpdateService
        .new(model: @principal, user: current_user)
        .call(pref: params.permit(:avatar_text).to_h)
    end
  end
end
