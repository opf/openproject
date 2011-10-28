#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AccountController < ApplicationController
  include CustomFieldsHelper

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required

  # Login request and validation
  def login
    if request.get?
      logout_user
    else
      authenticate_user
    end
  end

  # Log out current user and redirect to welcome page
  def logout
    logout_user
    redirect_to home_url
  end

  # Enable user to choose a new password
  def lost_password
    redirect_to(home_url) && return unless Setting.lost_password?
    if params[:token]
      @token = Token.find_by_action_and_value("recovery", params[:token])
      redirect_to(home_url) && return unless @token and !@token.expired?
      @user = @token.user
      if request.post?
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        if @user.save
          @token.destroy
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to :action => 'login'
          return
        end
      end
      render :template => "account/password_recovery"
      return
    else
      if request.post?
        user = User.find_by_mail(params[:mail])
        # user not found in db
        (flash.now[:error] = l(:notice_account_unknown_email); return) unless user
        # user uses an external authentification
        (flash.now[:error] = l(:notice_can_t_change_password); return) if user.auth_source_id
        # create a new token for password recovery
        token = Token.new(:user => user, :action => "recovery")
        if token.save
          Mailer.deliver_lost_password(token)
          flash[:notice] = l(:notice_account_lost_email_sent)
          redirect_to :action => 'login', :back_url => home_url
          return
        end
      end
    end
  end

  # User self-registration
  def register
    redirect_to(home_url) && return unless Setting.self_registration? || session[:auth_source_registration]
    if request.get?
      session[:auth_source_registration] = nil
      @user = User.new(:language => Setting.default_language)
    else
      @user = User.new(params[:user])
      @user.admin = false
      @user.register
      if session[:auth_source_registration]
        @user.activate
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        if @user.save
          session[:auth_source_registration] = nil
          self.logged_user = @user
          flash[:notice] = l(:notice_account_activated)
          redirect_to :controller => 'my', :action => 'account'
        end
      else
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]

        case Setting.self_registration
        when '1'
          register_by_email_activation(@user)
        when '3'
          register_automatically(@user)
        else
          register_manually_by_administrator(@user)
        end
      end
    end
  end

  # Token based account activation
  def activate
    redirect_to(home_url) && return unless Setting.self_registration? && params[:token]
    token = Token.find_by_action_and_value('register', params[:token])
    redirect_to(home_url) && return unless token and !token.expired?
    user = token.user
    redirect_to(home_url) && return unless user.registered?
    user.activate
    if user.save
      token.destroy
      flash[:notice] = l(:notice_account_activated)
    end
    redirect_to :action => 'login'
  end

  private

  def logout_user
    if User.current.logged?
      cookies.delete Redmine::Configuration['autologin_cookie_name']
      Token.delete_all(["user_id = ? AND action = ?", User.current.id, 'autologin'])
      self.logged_user = nil
    end
  end

  def authenticate_user
    if Setting.openid? && using_open_id?
      open_id_authenticate(params[:openid_url])
    else
      password_authentication
    end
  end

  def password_authentication
    user = User.try_to_login(params[:username], params[:password])

    if user.nil?
      invalid_credentials
    elsif user.new_record?
      onthefly_creation_failed(user, {:login => user.login, :auth_source_id => user.auth_source_id })
    else
      # Valid user
      successful_authentication(user)
    end
  end


  def open_id_authenticate(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :fullname, :email], :return_to => signin_url) do |result, identity_url, registration|
      if result.successful?
        user = User.find_or_initialize_by_identity_url(identity_url)
        if user.new_record?
          # Self-registration off
          redirect_to(home_url) && return unless Setting.self_registration?

          # Create on the fly
          user.login = registration['nickname'] unless registration['nickname'].nil?
          user.mail = registration['email'] unless registration['email'].nil?
          user.firstname, user.lastname = registration['fullname'].split(' ') unless registration['fullname'].nil?
          user.random_password
          user.register

          case Setting.self_registration
          when '1'
            register_by_email_activation(user) do
              onthefly_creation_failed(user)
            end
          when '3'
            register_automatically(user) do
              onthefly_creation_failed(user)
            end
          else
            register_manually_by_administrator(user) do
              onthefly_creation_failed(user)
            end
          end
        else
          # Existing record
          if user.active?
            successful_authentication(user)
          else
            account_pending
          end
        end
      end
    end
  end

  def successful_authentication(user)
    # Valid user
    self.logged_user = user
    # generate a key and set cookie if autologin
    if params[:autologin] && Setting.autologin?
      set_autologin_cookie(user)
    end
    call_hook(:controller_account_success_authentication_after, {:user => user })
    redirect_back_or_default :controller => 'my', :action => 'page'
  end

  def set_autologin_cookie(user)
    token = Token.create(:user => user, :action => 'autologin')
    cookie_options = {
      :value => token.value,
      :expires => 1.year.from_now,
      :path => Redmine::Configuration['autologin_cookie_path'],
      :secure => Redmine::Configuration['autologin_cookie_secure'],
      :httponly => true
    }
    cookies[Redmine::Configuration['autologin_cookie_name']] = cookie_options
  end

  # Onthefly creation failed, display the registration form to fill/fix attributes
  def onthefly_creation_failed(user, auth_source_options = { })
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render :action => 'register'
  end

  def invalid_credentials
    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
    flash.now[:error] = l(:notice_account_invalid_creditentials)
  end

  # Register a user for email activation.
  #
  # Pass a block for behavior when a user fails to save
  def register_by_email_activation(user, &block)
    token = Token.new(:user => user, :action => "register")
    if user.save and token.save
      Mailer.deliver_register(token)
      flash[:notice] = l(:notice_account_register_done)
      redirect_to :action => 'login'
    else
      yield if block_given?
    end
  end

  # Automatically register a user
  #
  # Pass a block for behavior when a user fails to save
  def register_automatically(user, &block)
    # Automatic activation
    user.activate
    user.last_login_on = Time.now
    if user.save
      self.logged_user = user
      flash[:notice] = l(:notice_account_activated)
      redirect_to :controller => 'my', :action => 'account'
    else
      yield if block_given?
    end
  end

  # Manual activation by the administrator
  #
  # Pass a block for behavior when a user fails to save
  def register_manually_by_administrator(user, &block)
    if user.save
      # Sends an email to the administrators
      Mailer.deliver_account_activation_request(user)
      account_pending
    else
      yield if block_given?
    end
  end

  def account_pending
    flash[:notice] = l(:notice_account_pending)
    redirect_to :action => 'login'
  end
end
