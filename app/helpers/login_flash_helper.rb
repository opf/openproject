##
# It's like the rails `flash`, but instead of living across requests it lives across consecutive logins.
# These values do not survive a logout, however.
module LoginFlashHelper
  def login_flash
    session[:login_flash] ||= Hash(session[:login_flash])
  end
end
