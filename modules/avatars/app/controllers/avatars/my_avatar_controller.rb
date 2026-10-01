module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    no_authorization_required! :update,
                               :destroy

    private

    def set_user
      @user = current_user
    end
  end
end
