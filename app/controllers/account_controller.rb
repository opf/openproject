#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AccountController < ApplicationController
  include CustomFieldsHelper
  include OmniauthHelper
  include Concerns::OmniauthLogin
  include Concerns::RedirectAfterLogin

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required

  # This prevents login CSRF
  # See AccountController#handle_unverified_request for more information.
  before_action :disable_api

  # Login request and validation
  def login
    user = User.current

    if user.logged?
      redirect_to home_url
    elsif omniauth_direct_login?
      direct_login(user)
    elsif request.post?
      authenticate_user
    end
  end

  # Log out current user and redirect to welcome page
  def logout
    logout_user
    if Setting.login_required? && omniauth_direct_login?
      flash.now[:notice] = I18n.t :notice_logged_out
      render :exit, locals: { instructions: :after_logout }
    else
      redirect_to home_url
    end
  end

  # Enable user to choose a new password
  def lost_password
    return redirect_to(home_url) unless allow_lost_password_recovery?

    if params[:token]
      @token = Token.find_by(action: 'recovery', value: params[:token].to_s)
      redirect_to(home_url) && return unless @token and !@token.expired?
      @user = @token.user
      if request.post?
        @user.password = params[:new_password]
        @user.password_confirmation = params[:new_password_confirmation]
        @user.force_password_change = false
        if @user.save
          @token.destroy
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to action: 'login'
          return
        end
      end
      render template: 'account/password_recovery'
      return
    else
      if request.post?
        user = User.find_by_mail(params[:mail])

        unless user
          # user not found in db
          (flash.now[:error] = l(:notice_account_unknown_email); return)
        end

        unless user.change_password_allowed?
          # user uses an external authentification
          (flash.now[:error] = l(:notice_can_t_change_password); return)
        end

        # create a new token for password recovery
        token = Token.new(user_id: user.id, action: 'recovery')
        if token.save
          UserMailer.password_lost(token).deliver_now
          flash[:notice] = l(:notice_account_lost_email_sent)
          redirect_to action: 'login', back_url: home_url
          return
        end
      end
    end
  end

  # User self-registration
  def register
    return self_registration_disabled unless allow_registration?

    @user = invited_user

    if request.get?
      registration_through_invitation!
    else
      if Setting.email_login?
        params[:user][:login] = params[:user][:mail]
      end

      self_registration!
    end
  end

  def allow_registration?
    allow = Setting.self_registration? && !OpenProject::Configuration.disable_password_login?

    invited = session[:invitation_token].present?
    get = request.get? && allow
    post = (request.post? || request.patch?) && (session[:auth_source_registration] || allow)

    invited || get || post
  end

  def allow_lost_password_recovery?
    Setting.lost_password? && !OpenProject::Configuration.disable_password_login?
  end

  # Token based account activation
  def activate
    token = Token.find_by value: params[:token].to_s

    if token && token.action == 'register' && Setting.self_registration?
      activate_self_registered token
    else
      activate_by_invite_token token
    end
  end

  def activate_self_registered(token)
    user = token.user

    if not user.registered?
      if user.active?
        flash[:notice] = I18n.t(:notice_account_already_activated)
      else
        flash[:error] = I18n.t(:notice_activation_failed)
      end

      redirect_to home_url
    else
      user.activate

      if user.save
        token.destroy
        flash[:notice] = with_accessibility_notice :notice_account_activated,
                                                   locale: user.language
      else
        flash[:error] = I18n.t(:notice_activation_failed)
      end

      redirect_to signin_path
    end
  end

  def activate_by_invite_token(token)
    if token.nil? || token.expired? || !token.user.invited?
      flash[:error] = I18n.t(:notice_account_invalid_token)

      redirect_to home_url
    else
      activate_invited token
    end
  end

  def activate_invited(token)
    session[:invitation_token] = token.value
    user = token.user

    if user.auth_source && user.auth_source.auth_method_name == 'LDAP'
      activate_through_ldap user
    else
      activate_user user
    end
  end

  def activate_user(user)
    if omniauth_direct_login?
      direct_login user
    elsif OpenProject::Configuration.disable_password_login?
      flash[:notice] = I18n.t('account.omniauth_login')

      redirect_to signin_path
    else
      redirect_to account_register_path
    end
  end

  def activate_through_ldap(user)
    session[:auth_source_registration] = {
      login: user.login,
      auth_source_id: user.auth_source_id
    }

    flash[:notice] = I18n.t('account.auth_source_login', login: user.login).html_safe

    redirect_to signin_path(username: user.login)
  end

  # Process a password change form, used when the user is forced
  # to change the password.
  # When making changes here, also check MyController.change_password
  def change_password
    return render_404 if OpenProject::Configuration.disable_password_login?

    @user = User.find_by_login(params[:username])
    @username = @user.login

    # A JavaScript hides the force_password_change field for external
    # auth sources in the admin UI, so this shouldn't normally happen.
    return if redirect_if_password_change_not_allowed(@user)

    if @user.check_password?(params[:password])
      @user.password = params[:new_password]
      @user.password_confirmation = params[:new_password_confirmation]
      @user.force_password_change = false
      if @user.save

        result = password_authentication(params[:username], params[:new_password])
        # password_authentication resets session including flash notices,
        # so set afterwards.
        flash[:notice] = l(:notice_account_password_updated)
        return result
      end
    else
      invalid_credentials
    end
    # Render the username to hint to a user in case of a forced password change
    render 'my/password', locals: { show_user_name: @user.force_password_change_was }
  end

  private

  def registration_through_invitation!
    session[:auth_source_registration] = nil

    if @user.nil?
      @user = User.new(language: Setting.default_language)
    elsif user_with_placeholder_name?(@user)
      # force user to give their name
      @user.firstname = nil
      @user.lastname = nil
    end
  end

  def self_registration!
    if @user.nil?
      @user = User.new
      @user.admin = false
      @user.register
    end

    if session[:auth_source_registration]
      # on-the-fly registration via omniauth or via auth source
      if pending_omniauth_registration?
        register_via_omniauth(@user, session, permitted_params)
      else
        register_and_login_via_authsource(@user, session, permitted_params)
      end
    else
      @user.attributes = permitted_params.user
      @user.login = params[:user][:login] if params[:user][:login].present?
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]

      register_user_according_to_setting @user
    end
  end

  def user_with_placeholder_name?(user)
    user.firstname == user.login and user.login == user.mail
  end

  def direct_login(user)
    if flash.empty?
      ps = {}.tap do |p|
        p[:origin] = params[:back_url] if params[:back_url]
      end

      redirect_to direct_login_provider_url(ps)
    else
      if Setting.login_required?
        error = user.active? || flash[:error]
        instructions = error ? :after_error : :after_registration

        render :exit, locals: { instructions: instructions }
      end
    end
  end

  def logout_user
    if User.current.logged?
      cookies.delete OpenProject::Configuration['autologin_cookie_name']
      Token.where(user_id: User.current.id, action: 'autologin').delete_all
      self.logged_user = nil
    end
  end

  def authenticate_user
    if OpenProject::Configuration.disable_password_login?
      render_404
    else
      password_authentication(params[:username], params[:password])
    end
  end

  def password_authentication(username, password)
    user = User.try_to_login(username, password, session)
    if user.nil?
      # login failed, now try to find out why and do the appropriate thing
      user = User.find_by_login(username)
      if user and user.check_password?(password)
        # correct password
        if not user.active?
          account_inactive(user, flash_now: true)
        elsif user.force_password_change
          return if redirect_if_password_change_not_allowed(user)
          render_password_change(I18n.t(:notice_account_new_password_forced))
        elsif user.password_expired?
          return if redirect_if_password_change_not_allowed(user)
          render_password_change(I18n.t(:notice_account_password_expired,
                                        days: Setting.password_days_valid.to_i))
        else
          invalid_credentials
        end
      elsif user and user.invited?
        invited_account_not_activated(user)
      else
        # incorrect password
        invalid_credentials
      end
    elsif user.new_record?
      onthefly_creation_failed(user, login: user.login, auth_source_id: user.auth_source_id)
    else
      # Valid user
      successful_authentication(user)
    end
  end

  def successful_authentication(user)
    # Valid user
    self.logged_user = user
    # generate a key and set cookie if autologin
    if params[:autologin] && Setting.autologin?
      set_autologin_cookie(user)
    end

    call_hook(:controller_account_success_authentication_after, user: user)

    redirect_after_login(user)
  end

  def set_autologin_cookie(user)
    token = Token.create(user: user, action: 'autologin')
    cookie_options = {
      value: token.value,
      expires: 1.year.from_now,
      path: OpenProject::Configuration['autologin_cookie_path'],
      secure: OpenProject::Configuration['autologin_cookie_secure'],
      httponly: true
    }
    cookies[OpenProject::Configuration['autologin_cookie_name']] = cookie_options
  end

  def login_user_if_active(user)
    if user.active?
      successful_authentication(user)
    else
      account_inactive(user, flash_now: false)
      redirect_to signin_path
    end
  end

  def pending_auth_source_registration?
    session[:auth_source_registration] && !pending_omniauth_registration?
  end

  def pending_omniauth_registration?
    Hash(session[:auth_source_registration])[:omniauth]
  end

  def register_and_login_via_authsource(_user, session, permitted_params)
    @user.attributes = permitted_params.user
    @user.activate
    @user.login = session[:auth_source_registration][:login]
    @user.auth_source_id = session[:auth_source_registration][:auth_source_id]

    if @user.save
      session[:auth_source_registration] = nil
      self.logged_user = @user
      flash[:notice] = with_accessibility_notice :notice_account_activated,
                                                 locale: @user.language
      redirect_to controller: '/my', action: 'account'
    end
    # Otherwise render register view again
  end

  # Onthefly creation failed, display the registration form to fill/fix attributes
  def onthefly_creation_failed(user, auth_source_options = {})
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render action: 'register'
  end

  def redirect_if_password_change_not_allowed(user)
    if user and not user.change_password_allowed?
      logger.warn "Password change for user '#{user}' forced, but user is not allowed " +
        'to change password'
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to action: 'login'
      return true
    end
    false
  end

  def render_password_change(message)
    flash[:error] = message
    @username = params[:username]
    # Render the username to hint to a user in case of a forced password change
    render 'my/password', locals: { show_user_name: true }
  end

  # Register a user depending on Setting.self_registration
  def register_user_according_to_setting(user, opts = {}, &block)
    return register_automatically(user, opts, &block) if user.invited?

    case Setting.self_registration
    when '1'
      register_by_email_activation(user, opts, &block)
    when '3'
      register_automatically(user, opts, &block)
    else
      register_manually_by_administrator(user, opts, &block)
    end
  end

  # Register a user for email activation.
  #
  # Pass a block for behavior when a user fails to save
  def register_by_email_activation(user, _opts = {})
    token = Token.new(user: user, action: 'register')
    if user.save and token.save
      UserMailer.user_signed_up(token).deliver_now
      flash[:notice] = l(:notice_account_register_done)
      redirect_to action: 'login'
    else
      yield if block_given?
    end
  end

  # Automatically register a user
  #
  # Pass a block for behavior when a user fails to save
  def register_automatically(user, opts = {})
    # Automatic activation
    user.activate
    user.last_login_on = Time.now

    if user.save
      self.logged_user = user
      opts[:after_login].call user if opts[:after_login]

      flash[:notice] = with_accessibility_notice :notice_account_registered_and_logged_in,
                                                 locale: user.language
      redirect_after_login(user)
    else
      yield if block_given?
    end
  end

  # Manual activation by the administrator
  #
  # Pass a block for behavior when a user fails to save
  def register_manually_by_administrator(user, _opts = {})
    if user.save
      # Sends an email to the administrators
      admins = User.admin.active
      admins.each do |admin|
        UserMailer.account_activation_requested(admin, user).deliver_now
      end
      account_pending
    else
      yield if block_given?
    end
  end

  def self_registration_disabled
    flash[:error] = I18n.t('account.error_self_registration_disabled')
    redirect_to signin_url
  end

  # Call if an account is inactive - either registered or locked
  def account_inactive(user, flash_now: true)
    if user.registered?
      account_not_activated(flash_now: flash_now)
    else
      invalid_credentials(flash_now: flash_now)
    end
  end

  # Log an attempt to log in to an account in "registered" state and show a flash message.
  def account_not_activated(flash_now: true)
    flash_hash = flash_now ? flash.now : flash

    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip}" \
                " at #{Time.now.utc} (NOT ACTIVATED)"

    if Setting.self_registration == '1'
      flash_hash[:error] = I18n.t('account.error_inactive_activation_by_mail')
    else
      flash_hash[:error] = I18n.t('account.error_inactive_manual_activation')
    end
  end

  def invited_account_not_activated(user)
    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip}" \
                " at #{Time.now.utc} (invited, NOT ACTIVATED)"

    flash[:error] = I18n.t('account.error_inactive_activation_by_mail')
  end

  # Log an attempt to log in to a locked account or with invalid credentials
  # and show a flash message.
  def invalid_credentials(flash_now: true)
    flash_hash = flash_now ? flash.now : flash

    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip}" \
                " at #{Time.now.utc}"

    if Setting.brute_force_block_after_failed_logins.to_i == 0
      flash_hash[:error] = I18n.t(:notice_account_invalid_credentials)
    else
      flash_hash[:error] = I18n.t(:notice_account_invalid_credentials_or_blocked)
    end
  end

  def account_pending
    flash[:notice] = l(:notice_account_pending)
    # Set back_url to make sure user is not redirected to an external login page
    # when registering via the external service. This also redirects the user
    # to the original page where the user clicked on the omniauth login link for a provider.
    redirect_to action: 'login', back_url: params[:back_url]
  end

  def invited_user
    if session.include? :invitation_token
      token = Token.find_by(value: session[:invitation_token])

      token.user
    end
  end

  def with_accessibility_notice(key, locale:)
    locale = locale.presence || I18n.locale
    text = I18n.t(key, locale: locale)
    notice = link_translate(:notice_accessibility_mode,
                            links: { url: my_settings_url },
                            locale: locale)

    "#{text} #{notice}".html_safe
  end
end
