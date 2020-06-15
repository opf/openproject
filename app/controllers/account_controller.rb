#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
  include Accounts::OmniauthLogin
  include Accounts::RedirectAfterLogin
  include Accounts::AuthenticationStages
  include Accounts::UserConsent
  include Accounts::UserLimits
  include Accounts::UserPasswordChange

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_action :check_if_login_required

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
    # Keep attributes from the session
    # to identify the user
    previous_session = session.to_h.with_indifferent_access
    previous_user = current_user

    logout_user

    perform_post_logout previous_session, previous_user
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
        UserMailer.password_lost(token).deliver_later
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

      call_hook :user_registered, { user: @user } if @user.persisted?
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

    if token.nil? || token.user.nil?
      invalid_token_and_redirect
    elsif token.expired?
      handle_expired_token token
    elsif token.user.invited?
      activate_by_invite_token token
    elsif Setting.self_registration?
      activate_self_registered token
    else
      invalid_token_and_redirect
    end
  end

  def handle_expired_token(token)
    new_token = Token::Invitation.create!(user: token.user)
    UserMailer.user_signed_up(new_token).deliver_later

    flash[:warning] = I18n.t :warning_registration_token_expired, email: token.user.mail

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
    return if enforce_activation_user_limit(user: token.user)

    activate_invited token
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
    @user = User.find(params[:password_change_user_id])

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
        @user.assign_attributes permitted_params.user_register_via_omniauth
        register_via_omniauth(session, @user.attributes)
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

      call = ::Users::RegisterUserService.new(@user).call

      if call.success?
        flash[:notice] = call.message.presence
        login_user_if_active(call.result, just_registered: true)
      else
        flash[:error] = error = call.message
        Rails.logger.error "Registration of user #{@user.login} failed: #{error}"
        onthefly_creation_failed(@user, login: @user.login)
      end
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
    elsif Setting.login_required?
      # I'm not sure why it is considered an error if we don't have the anonymous user here.
      # Before the line read `user.active? || flash[:error]` but since a recent
      # change the anonymous user is active too which breaks this.
      error = !user.anonymous? || flash[:error]
      instructions = error ? :after_error : :after_registration

      render :exit, locals: { instructions: instructions }
    end
  end

  def authenticate_user
    if OpenProject::Configuration.disable_password_login?
      render_404
    else
      password_authentication(params[:username]&.strip, params[:password])
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

  def successful_authentication(user, reset_stages: true, just_registered: false)
    stages = authentication_stages after_activation: just_registered, reset: reset_stages

    if stages.empty?
      # setting params back_url to be used by redirect_after_login
      params[:back_url] = session.delete :back_url if session.include?(:back_url)

      if just_registered || session[:just_registered]
        finish_registration! user
      else
        login_user! user
      end
    else
      stage = stages.first

      session[:just_registered] = just_registered
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

  def login_user_if_active(user, just_registered:)
    if user.active?
      successful_authentication(user, just_registered: just_registered)
      return
    end

    # Show an appropriate error unless
    # the user was just registered
    if !(just_registered && user.registered?)
      account_inactive(user, flash_now: false)
    end

    redirect_to signin_path(back_url: params[:back_url])
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

  def finish_registration!(user)
    session[:just_registered] = nil
    self.logged_user = user
    user.update last_login_on: Time.now

    flash[:notice] = I18n.t(:notice_account_registered_and_logged_in)
    redirect_after_login user
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

  def invited_user
    if session.include? :invitation_token
      token = Token::Invitation.find_by_plaintext_value session[:invitation_token]

      token.user
    end
  end

  def disable_api
    # Changing this to not use api_request? to determine whether a request is an API
    # request can have security implications regarding CSRF. See handle_unverified_request
    # for more information.
    head 410 if api_request?
  end

  def invalid_token_and_redirect
    flash[:error] = I18n.t(:notice_account_invalid_token)

    redirect_to home_url
  end
end
