# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "uri"

##
# Intended to be used by the AccountController and OmniAuthLoginController to handle registration flows
module Accounts::Registration
  ##
  # Sends a user who was just registered to the activation stages
  # or to the signin page if the user could not be activated
  def login_user_if_active(user, just_registered:)
    if user.active?
      successful_authentication(user, just_registered:)
      return
    end

    # Show an appropriate error unless
    # the user was just registered
    if !(just_registered && user.registered?)
      account_inactive(user, flash_now: false)
    end

    redirect_to signin_path(back_url: params[:back_url])
  end

  def register_plain_user(user) # rubocop:disable Metrics/AbcSize
    user.attributes = permitted_params.user.transform_values do |val|
      if val.is_a? String
        val.strip!
      end

      val
    end
    user.login = params[:user][:login].strip if params[:user][:login].present?
    user.password = params[:user][:password]
    user.password_confirmation = params[:user][:password_confirmation]

    respond_for_registered_user(user)
  end

  def register_with_auth_source(user) # rubocop:disable Metrics/AbcSize
    # on-the-fly registration via omniauth or via auth source
    if pending_omniauth_registration?
      user.assign_attributes permitted_params.user_register_via_omniauth
      register_via_omniauth(session, user.attributes)
    else
      user.attributes = permitted_params.user
      user.activate
      user.login = session[:auth_source_registration][:login]
      user.ldap_auth_source_id = session[:auth_source_registration][:ldap_auth_source_id]

      respond_for_registered_user(user)
    end
  end

  def register_via_omniauth(session, user_attributes)
    handle_omniauth_authentication(session[:auth_source_registration], user_params: user_attributes)
  end

  def handle_omniauth_authentication(auth_hash, user_params: nil) # rubocop:disable Metrics/AbcSize
    call = ::Authentication::OmniauthService
      .new(strategy: request.env["omniauth.strategy"], auth_hash:, controller: self)
      .call(user_params)

    if call.success?
      session[:omniauth_provider] = auth_hash[:provider]
      flash[:notice] = call.message if call.message.present?
      login_user_if_active(call.result, just_registered: call.result.just_created?)
    elsif call.includes_error?(:base, :failed_to_activate)
      redirect_omniauth_register_modal(call.result, auth_hash)
    else
      error = call.message
      Rails.logger.error "Authorization request failed: #{error}"
      show_error error
    end
  end

  def redirect_omniauth_register_modal(user, auth_hash)
    # Store a timestamp so we can later make sure that authentication information can
    # only be reused for a short time.
    session[:auth_source_registration] = auth_hash.merge(omniauth: true, timestamp: Time.current)
    @user = user
    render template: "/account/register"
  end

  def respond_for_registered_user(user)
    call = ::Users::RegisterUserService.new(user).call

    if call.success?
      flash[:notice] = call.message.presence
      login_user_if_active(call.result, just_registered: true)
    else
      flash[:error] = error = call.message
      Rails.logger.error "Registration of user #{user.login} failed: #{error}"
      onthefly_creation_failed(user)
    end
  end

  # Onthefly creation failed, display the registration form to fill/fix attributes
  def onthefly_creation_failed(user, auth_source_options = {})
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render action: "register", status: :unprocessable_entity
  end

  def self_registration_disabled
    flash[:error] = I18n.t("account.error_self_registration_disabled")
    redirect_to signin_url
  end

  def account_inactive(user, flash_now: true)
    if user.registered?
      account_not_activated(flash_now:)
    else
      flash_and_log_invalid_credentials(flash_now:)
    end
  end

  def pending_omniauth_registration?
    Hash(session[:auth_source_registration])[:omniauth]
  end

  def show_error(error)
    flash[:error] = error
    redirect_to signin_path
  end

  # Log an attempt to log in to an account in "registered" state and show a flash message.
  def account_not_activated(flash_now: true)
    flash_error_message(log_reason: "NOT ACTIVATED", flash_now:) do
      if Setting::SelfRegistration.by_email?
        "account.error_inactive_activation_by_mail"
      else
        "account.error_inactive_manual_activation"
      end
    end
  end
end
