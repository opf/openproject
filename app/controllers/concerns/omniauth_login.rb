##
# Intended to be used by the AccountController to handle omniauth logins
module Concerns::OmniauthLogin
  def self.included(base)
    # disable CSRF protection since that should be covered by the omniauth strategy
    base.skip_before_filter :verify_authenticity_token, :only => [:omniauth_login]
  end

  def omniauth_login
    auth_hash = request.env['omniauth.auth']

    return render_400 unless auth_hash.valid?

    # Set back url to page the omniauth login link was clicked on
    params[:back_url] = request.env['omniauth.origin']

    user = User.find_or_initialize_by_identity_url(identity_url_from_omniauth(auth_hash))
    if user.new_record?
      create_user_from_omniauth(user, auth_hash)
    else
      user.log_successful_login if user.active?
      login_user_if_active(user)
    end
  end

  def omniauth_failure
    logger.warn(params[:message]) if params[:message]
    flash[:error] = I18n.t(:error_external_authentication_failed)
    redirect_to :action => 'login'
  end

  def self.direct_login?
    direct_login_provider.is_a? String
  end

  ##
  # Per default the user may choose the usual password login as well as several omniauth providers
  # on the login page and in the login drop down menu.
  #
  # With his configuration option you can set a specific omniauth provider to be
  # used for direct login. Meaning that the login provider selection is skipped and
  # the configured provider is used directly instead.
  #
  # If this option is active /login will lead directly to the configured omniauth provider
  # and so will a click on 'Sign in' (as opposed to opening the drop down menu).
  def self.direct_login_provider
    OpenProject::Configuration['omniauth_direct_login_provider']
  end

  def self.direct_login_provider_url
    "/auth/#{direct_login_provider}" if direct_login?
  end

  ##
  # Activating this leaves omniauth as the only way to authenticate.
  def self.disable_password_login?
    value = OpenProject::Configuration['disable_password_login']

    ['true', true].include? value
  end

  private

  # a user may login via omniauth and (if that user does not exist
  # in our database) will be created using this method.
  def create_user_from_omniauth(user, auth_hash)
    # Self-registration off
    return self_registration_disabled unless Setting.self_registration?

    # Create on the fly
    fill_user_fields_from_omniauth(user, auth_hash)

    register_user_according_to_setting(user) do
      # Allow registration form to show provider-specific title
      @omniauth_strategy = auth_hash[:provider]

      # Store a timestamp so we can later make sure that authentication information can
      # only be reused for a short time.
      session_info = auth_hash.merge(omniauth: true, timestamp: Time.new)

      onthefly_creation_failed(user, session_info)
    end
  end

  def register_via_omniauth(user, session, permitted_params)
    auth = session[:auth_source_registration]
    return if handle_omniauth_registration_expired(auth)

    fill_user_fields_from_omniauth(@user, auth)
    @user.update_attributes(permitted_params.user_register_via_omniauth)
    register_user_according_to_setting(@user)
  end

  def fill_user_fields_from_omniauth(user, auth)
    info = auth[:info]
    user.update_attributes login:        info[:email],
                           mail:         info[:email],
                           firstname:    info[:first_name] || info[:name],
                           lastname:     info[:last_name],
                           identity_url: identity_url_from_omniauth(auth)
    user.register
    user
  end

  def identity_url_from_omniauth(auth)
    "#{auth[:provider]}:#{auth[:uid]}"
  end

  # if the omni auth registration happened too long ago,
  # we don't accept it anymore.
  def handle_omniauth_registration_expired(auth)
    if auth['timestamp'] < Time.now - 30.minutes
      flash[:error] = I18n.t(:error_omniauth_registration_timed_out)
      redirect_to(signin_url)
    end
  end
end
