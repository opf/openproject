module My
  class AutoLoginTokensController < ::ApplicationController
    before_action :find_token, only: %i(destroy)

    layout 'my'
    menu_item :sessions

    def destroy
      @token.destroy

      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to my_sessions_path
    end

    private

    def find_token
      @token = Token::AutoLogin
        .for_user(current_user)
        .find(params[:id])
    end
  end
end
