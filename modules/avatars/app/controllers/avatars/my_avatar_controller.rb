module ::Avatars
  class MyAvatarController < BaseController
    before_action :require_login
    before_action :set_user

    no_authorization_required! :update_settings,
                               :destroy

    private

    def redirect_path
      my_account_path
    end

    def set_user
      @principal = current_user
    end
  end
end
