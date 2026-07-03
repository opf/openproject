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
      edit_user_path(@user)
    end

    def find_user
      @user = User.visible.find(params[:id])
    end
  end
end
