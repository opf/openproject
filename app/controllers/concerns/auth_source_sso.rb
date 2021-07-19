##
# If OPENPROJECT_AUTH__SOURCE__SSO_HEADER and OPENPROJECT_AUTH__SOURCE__SSO_SECRET are
# configured OpenProject will login the user given in the HTTP header with the given name
# together with the secret in the form of `login:$secret`.
module AuthSourceSSO
  def find_current_user
    user = super

    # Do nothing if sso disabled
    return user unless auth_source_sso_enabled?
    # Return super auth if SSO already in progress
    return user if sso_in_progress!

    # Get the header-provided login value
    login = read_sso_login

    # Log out the current user if the login does not match
    logged_user = match_sso_with_logged_user(login, user)

    # Return the logged in user if matches
    return logged_user if logged_user.present?

    Rails.logger.debug { "Starting header-based auth source SSO for #{header_name}='#{op_auth_header_value}'" }
    perform_header_sso login
  end

  def match_sso_with_logged_user(login, user)
    return if user.nil?
    return user if user.login == login

    Rails.logger.warn { "Header-based auth source SSO user changed from #{user.login} to #{login}. Re-authenticating" }
    ::Users::LogoutService.new(controller: self).call(user)

    nil
  end

  def perform_header_sso(login)
    if login
      user = find_user_from_auth_source(login) || create_user_from_auth_source(login)

      handle_sso_for! user, login
    else
      handle_sso_failure!
    end
  end

  def read_sso_login
    get_validated_login! op_auth_header_value
  end

  def sso_config
    @sso_config ||= OpenProject::Configuration.auth_source_sso.try(:with_indifferent_access)
  end

  def auth_source_sso_enabled?
    header_name.present?
  end

  def op_auth_header_value
    String(request.headers[header_name])
  end

  def header_name
    sso_config && sso_config[:header]
  end

  def header_secret
    sso_config && sso_config[:secret]
  end

  def header_optional?
    sso_config && sso_config[:optional]
  end

  def header_slo_url
    sso_config && sso_config[:logout_url]
  end

  def get_validated_login!(value)
    login, valid_secret = extract_from_header(value)

    unless valid_secret
      Rails.logger.error("Secret contained in auth source SSO header #{header_name} is not valid.")
      return nil
    end

    unless login.present?
      Rails.logger.error("Provided SSO header #{header_name} is empty or not valid.")
      return nil
    end

    login
  end

  def extract_from_header(value)
    if header_secret.present?
      valid_secret = value.end_with?(":#{header_secret}")
      login = value.gsub(/:#{Regexp.escape(header_secret)}\z/, '')

      [login, valid_secret]
    else
      [value, true]
    end
  end

  def find_user_from_auth_source(login)
    User.where(login: login).where.not(auth_source_id: nil).first
  end

  def create_user_from_auth_source(login)
    if attrs = AuthSource.find_user(login)
      # login is both safe and protected in chilis core code
      # in case it's intentional we keep it that way
      user = User.new attrs.except(:login)
      user.login = login
      user.language = Setting.default_language

      save_user! user

      user
    end
  end

  def save_user!(user)
    if user.save
      user.reload

      if logger && user.auth_source
        logger.info(
          "User '#{user.login}' created from external auth source: " +
            "#{user.auth_source.type} - #{user.auth_source.name}"
        )
      end
    end
  end

  def sso_in_progress!
    sso_failure_in_progress! || session[:auth_source_registration] || session[:authenticated_user_id]
  end

  def sso_failure_in_progress!
    failure = session[:auth_source_sso_failure]

    if failure
      if failure[:ttl] > 0
        session[:auth_source_sso_failure] = failure.merge(ttl: failure[:ttl] - 1)
      else
        session.delete :auth_source_sso_failure

        nil
      end
    end
  end

  def sso_login_failed?(user)
    user.nil? || user.new_record? || !(user.active? || user.invited?)
  end

  def handle_sso_for!(user, login)
    if sso_login_failed?(user)
      handle_sso_failure!({ user: user, login: login })
    else # valid user
      # If a user is invited, ensure it gets activated
      activated = user.invited?
      activate_user_if_invited! user

      handle_sso_success user, activated
    end
  end

  def handle_sso_success(user, just_activated)
    session[:user_from_auth_header] = true
    successful_authentication(user, reset_stages: true, just_registered: just_activated)
  end

  def activate_user_if_invited!(user)
    return unless user.invited?

    user.active!
  end

  def perform_post_logout(prev_session, previous_user)
    if prev_session[:user_from_auth_header] && header_slo_url.present?
      redirect_to header_slo_url
    else
      super
    end
  end

  def handle_sso_failure!(session_args = {})
    return if header_optional?

    session[:auth_source_sso_failure] = session_args.merge(
      back_url: request.base_url + request.original_fullpath,
      ttl: 1
    )

    redirect_to sso_failure_path
  end
end
