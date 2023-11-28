module My
  class SessionsController < ::ApplicationController
    before_action :require_login
    self._model_object = ::Sessions::UserSession

    before_action :find_model_object, only: %i(show destroy)
    before_action :prevent_current_session_deletion, only: %i(destroy)

    layout 'my'
    menu_item :sessions

    def index
      @sessions = ::Sessions::UserSession
        .for_user(current_user)
        .order(updated_at: :desc)

      @autologin_tokens = ::Token::AutoLogin
        .for_user(current_user)
        .order(expires_on: :asc)

      token = cookies[OpenProject::Configuration['autologin_cookie_name']]
      if token
        @current_token = @autologin_tokens.find_by_plaintext_value(token) # rubocop:disable Rails/DynamicFindBy
      end
    end

    def show; end

    def destroy
      @session.delete

      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to action: :index
    end

    private

    def prevent_current_session_deletion
      if @session.current?(session)
        render_400 message: I18n.t('users.sessions.may_not_delete_current')
      end
    end
  end
end
