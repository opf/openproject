module Accounts::UserLogin
  include ::Accounts::AuthenticationStages
  include ::Accounts::RedirectAfterLogin

  def login_user!(user)
    # Set the logged user, resetting their session
    self.logged_user = user

    call_hook(:controller_account_success_authentication_after, user:)

    redirect_after_login(user)
  end

  ##
  # Log an attempt to log in to a locked account or with invalid credentials
  # and show a flash message.
  def flash_and_log_invalid_credentials(flash_now: true, is_logged_in: false)
    if is_logged_in
      flash[:error] = I18n.t(:notice_account_wrong_password)
      return
    end

    flash_error_message(log_reason: "invalid credentials", flash_now:) do
      if Setting.brute_force_block_after_failed_logins.to_i > 0
        :notice_account_invalid_credentials_or_blocked
      else
        :notice_account_invalid_credentials
      end
    end
  end

  def flash_error_message(log_reason: "", flash_now: true)
    flash_hash = flash_now ? flash.now : flash

    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} " \
                "at #{Time.now.utc}: #{log_reason}"

    flash_message = yield

    flash_hash[:error] = I18n.t(flash_message)
  end
end
