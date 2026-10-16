module ::Avatars
  class UsersController < BaseController
    before_action :require_admin
    before_action :find_user

    layout "admin", except: :show

    def show
      redirect_to redirect_path
    end

    private

    def redirect_path
      edit_user_path(@principal)
    end

    def find_user
      @principal = User.visible.find(params.expect(:id))
    end

    def update_color_request
      ::Users::UpdateService
        .new(model: @principal, user: current_user)
        .call(pref: { avatar_color: params[:avatar_color] })
    end
  end
end
