#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class AccountController < ApplicationController
  include CustomFieldsHelper
  include OmniauthHelper
  include Concerns::OmniauthLogin
  include Concerns::RedirectAfterLogin
  include Concerns::AuthenticationStages
  include Concerns::UserConsent
  include Concerns::UserLimits
  include Concerns::UserPasswordChange

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required

  # This prevents login CSRF
  # See AccountController#handle_unverified_request for more information.
  before_action :disable_api

  before_action :check_auth_source_sso_failure, only: :auth_source_sso_failed

  layout 'no_menu'

  # Login request and validation
  def login
    user = User.current

    if user.logged?
      redirect_after_login(user)
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
      @token = ::Token::Recovery.find_by_plaintext_value(params[:token])
      redirect_to(home_url) && return unless @token and !@token.expired?
      @user = @token.user
      if request.post?
        call = ::Users::ChangePasswordService.new(current_user: @user, session: session).call(params)
        call.apply_flash_message!(flash)

        if call.success?
          @token.destroy
          redirect_to action: 'login'
          return
        end
      end

      render template: 'account/password_recovery'
    elsif request.post?
      mail = params[:mail]
      user = User.find_by_mail(mail) if mail.present?

      # Ensure the same request is sent regardless of which email is entered
      # to avoid detecability of mails
      flash[:notice] = l(:notice_account_lost_email_sent)

      unless user
        # user not found in db
        Rails.logger.error "Lost password unknown email input: #{mail}"
        return
      end

      unless user.change_password_allowed?
        # user uses an external authentification
        Rails.logger.error "Password cannot be changed for user: #{mail}"
        return
      end

      # create a new token for password recovery
      token = Token::Recovery.new(user_id: user.id)
      if token.save
        UserMailer.password_lost(token).deliver_now
        flash[:notice] = l(:notice_account_lost_email_sent)
        redirect_to action: 'login', back_url: home_url
        return
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
    token = ::Token::Invitation.find_by_plaintext_value(params[:token])

    if token.nil? || token.expired? || token.user.nil?
      handle_expired_token token
    elsif token.user.invited?
      activate_by_invite_token token
    elsif Setting.self_registration?
      activate_self_registered token
    else
      flash[:error] = I18n.t(:notice_account_invalid_token)

      redirect_to home_url
    end
  end

  def handle_expired_token(token)
    if token.nil?
      flash[:error] = I18n.t :notice_account_invalid_token
    elsif token.expired?
      send_activation_email! Token::Invitation.create!(user: token.user)

      flash[:warning] = I18n.t :warning_registration_token_expired, email: token.user.mail
    end

    redirect_to home_url
  end

  def activate_self_registered(token)
    return if enforce_activation_user_limit(user: token.user)

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
        flash[:notice] = I18n.t(:notice_account_activated)
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
      return if enforce_activation_user_limit(user: token.user)

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
    # Retrieve user_id from session
    @user = User.find(flash[:_password_change_user_id])

    change_password_flow(user: @user, params: params, show_user_name: true) do
      password_authentication(@user.login, params[:new_password])
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Failed to find user for change_password request: #{flash[:_password_change_user_id]}"
    render_404
  end

  def auth_source_sso_failed
    failure = session.delete :auth_source_sso_failure
    user = failure[:user]

    if user.try(:new_record?)
      return onthefly_creation_failed user, login: user.login, auth_source_id: user.auth_source_id
    end

    show_sso_error_for user

    flash.now[:error] = I18n.t(:error_auth_source_sso_failed, value: failure[:login]) +
      ": " + String(flash.now[:error])

    render action: 'login', back_url: failure[:back_url]
  end

  private

  def check_auth_source_sso_failure
    redirect_to home_url unless session[:auth_source_sso_failure].present?
  end

  def show_sso_error_for(user)
    if user.nil?
      flash_and_log_invalid_credentials
    elsif not user.active?
      account_inactive user, flash_now: true
    end
  end

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

    return if enforce_activation_user_limit(user: user_with_email(@user))

    # Set consent if received from registration form
    if consent_param?
      @user.consented_at = DateTime.now
    end

    if session[:auth_source_registration]
      # on-the-fly registration via omniauth or via auth source
      if pending_omniauth_registration?
        register_via_omniauth(@user, session, permitted_params)
      else
        register_and_login_via_authsource(@user, session, permitted_params)
      end
    else
      @user.attributes = permitted_params.user.transform_values do |val|
        if val.is_a? String
          val.strip!
        end

        val
      end
      @user.login = params[:user][:login].strip if params[:user][:login].present?
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
      Token::AutoLogin.where(user_id: current_user.id).delete_all
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
          render_password_change(user, I18n.t(:notice_account_new_password_forced), show_user_name: true)
        elsif user.password_expired?
          return if redirect_if_password_change_not_allowed(user)
          render_password_change(user, I18n.t(:notice_account_password_expired, days: Setting.password_days_valid.to_i), show_user_name: true)
        else
          flash_and_log_invalid_credentials
        end
      elsif user and user.invited?
        invited_account_not_activated(user)
      else
        # incorrect password
        flash_and_log_invalid_credentials
      end
    elsif user.new_record?
      onthefly_creation_failed(user, login: user.login, auth_source_id: user.auth_source_id)
    else
      # Valid user
      successful_authentication(user)
    end
  end

  def successful_authentication(user, reset_stages: true)
    stages = authentication_stages reset: reset_stages

    if stages.empty?
      # setting params back_url to be used by redirect_after_login
      params[:back_url] = session.delete :back_url if session.include?(:back_url)

      if session[:finish_registration]
        finish_registration! user
      else
        login_user! user
      end
    else
      stage = stages.first

      session[:authenticated_user_id] = user.id

      redirect_to stage.path
    end
  end

  def login_user!(user)
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

  def login_user_if_active(user)
    if user.active?
      successful_authentication(user)
    else
      account_inactive(user, flash_now: false)
      redirect_to signin_path
    end
  end

  def send_activation_email!(token)
    UserMailer.user_signed_up(token).deliver_now
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
      flash[:notice] = I18n.t(:notice_account_activated)
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
    token = Token::Invitation.new(user: user)

    if user.save and token.save
      send_activation_email! token
      flash[:notice] = I18n.t(:notice_account_register_done)

      redirect_to action: 'login'
    else
      yield if block_given?
    end
  end

  # Automatically register a user
  #
  # Pass a block for behavior when a user fails to save
  def register_automatically(user, opts = {})
    if user_limit_reached?
      show_user_limit_activation_error!
      send_activation_limit_notification_about user

      return redirect_back fallback_location: signin_path
    end

    # Automatic activation
    user.activate

    if user.save
      stages = authentication_stages after_activation: true

      run_registration_stages stages, user, opts
    else
      yield if block_given?
    end
  end

  def run_registration_stages(stages, user, opts)
    if stages.empty?
      finish_registration! user, opts
    else
      stage = stages.first

      session[:authenticated_user_id] = user.id
      session[:finish_registration] = opts

      redirect_to stage.path
    end
  end

  def finish_registration!(user, opts = Hash(session.delete(:finish_registration)))
    self.logged_user = user
    user.update last_login_on: Time.now

    if auth_hash = opts[:omni_auth_hash]
      OpenProject::OmniAuth::Authorization.after_login! user, auth_hash, self
    end

    flash[:notice] = I18n.t(:notice_account_registered_and_logged_in)
    redirect_after_login user
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
      flash_and_log_invalid_credentials(flash_now: flash_now)
    end
  end

  # Log an attempt to log in to an account in "registered" state and show a flash message.
  def account_not_activated(flash_now: true)
    flash_error_message(log_reason: 'NOT ACTIVATED', flash_now: flash_now) do
      if Setting.self_registration == '1'
        'account.error_inactive_activation_by_mail'
      else
        'account.error_inactive_manual_activation'
      end
    end
  end

  def invited_account_not_activated(user)
    flash_error_message(log_reason: 'invited, NOT ACTIVATED', flash_now: false) do
      'account.error_inactive_activation_by_mail'
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
      token = Token::Invitation.find_by_plaintext_value session[:invitation_token]

      token.user
    end
  end
end
