module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    no_authorization_required! :update,
                               :destroy,
                               :update_color

    private

    def set_user
      @principal = current_user
    end

    def update_color_request
      ::Users::UpdateService
        .new(model: @principal, user: current_user)
        .call(pref: { avatar_color: params[:avatar_color] })
    end
  end
end
