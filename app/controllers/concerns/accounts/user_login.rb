module Accounts::UserLogin
  include ::Accounts::AuthenticationStages
  include ::Accounts::RedirectAfterLogin

  def login_user!(user)
    # generate a key and set cookie if autologin
    if Setting.autologin? && (params[:autologin] || session.delete(:autologin_requested))
      set_autologin_cookie(user)
    end

    # Set the logged user, resetting their session
    self.logged_user = user

    call_hook(:controller_account_success_authentication_after, user: user)

    redirect_after_login(user)
  end

  def set_autologin_cookie(user)
    token = Token::AutoLogin.create(user: user)
    cookie_options = {
      value: token.plain_value,
      expires: 1.year.from_now,
      path: OpenProject::Configuration['autologin_cookie_path'],
      secure: OpenProject::Configuration['autologin_cookie_secure'],
      httponly: true
    }
    cookies[OpenProject::Configuration['autologin_cookie_name']] = cookie_options
  end
end
