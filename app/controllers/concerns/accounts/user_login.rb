module Accounts::UserLogin
  include ::Accounts::AuthenticationStages
  include ::Accounts::RedirectAfterLogin

  def login_user!(user)
    # Set the logged user, resetting their session
    self.logged_user = user

    call_hook(:controller_account_success_authentication_after, user:)

    redirect_after_login(user)
  end
end
