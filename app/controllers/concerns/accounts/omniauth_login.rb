#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'uri'

##
# Intended to be used by the AccountController to handle omniauth logins
module Accounts::OmniauthLogin
  extend ActiveSupport::Concern

  included do
    # disable CSRF protection since that should be covered by the omniauth strategy
    # the other filters are not applicable either since OmniAuth is doing authentication
    # itself
    %i[
      verify_authenticity_token user_setup
      check_if_login_required check_session_lifetime
    ]
      .each { |key| skip_before_action key, only: [:omniauth_login] }

    helper :omniauth
  end

  def omniauth_login
    params[:back_url] = request.env['omniauth.origin'] if remember_back_url?

    # Extract auth info and perform check / login or activate user
    auth_hash = request.env['omniauth.auth']
    handle_omniauth_authentication(auth_hash)
  end

  def omniauth_failure
    logger.warn(params[:message]) if params[:message]
    show_error I18n.t(:error_external_authentication_failed)
  end

  def direct_login_provider_url(params = {})
    omniauth_start_url(direct_login_provider, params)
  end

  private

  def redirect_omniauth_register_modal(user, auth_hash)
    # Store a timestamp so we can later make sure that authentication information can
    # only be reused for a short time.
    session_info = auth_hash.merge(omniauth: true, timestamp: Time.new)

    onthefly_creation_failed(user, session_info)
  end

  # Avoid remembering the back_url if we're coming from the login page
  def remember_back_url?
    provided_back_url = request.env['omniauth.origin']
    return if provided_back_url.blank?

    account_routes = /\/(login|account)/
    omniauth_direct_login? || !provided_back_url.match?(account_routes)
  end

  def show_error(error)
    flash[:error] = error
    redirect_to action: 'login'
  end

  def register_via_omniauth(session, user_attributes)
    handle_omniauth_authentication(session[:auth_source_registration], user_params: user_attributes)
  end

  def handle_omniauth_authentication(auth_hash, user_params: nil)
    call = ::Authentication::OmniauthService
      .new(strategy: request.env['omniauth.strategy'], auth_hash:, controller: self)
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
end
