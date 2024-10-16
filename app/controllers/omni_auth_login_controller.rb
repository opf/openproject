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

class OmniAuthLoginController < ApplicationController
  include OmniauthHelper
  include Accounts::Registration
  include Accounts::UserLogin

  # disable CSRF protection since that should be covered by the omniauth strategy
  # the other filters are not applicable either since OmniAuth is doing authentication
  # itself

  skip_before_action :verify_authenticity_token
  skip_before_action :user_setup
  skip_before_action :check_if_login_required
  skip_before_action :check_session_lifetime

  no_authorization_required! :callback, :failure

  helper :omniauth

  layout "no_menu"

  def callback
    params[:back_url] = omniauth_back_url if remember_back_url?

    # Extract auth info and perform check / login or activate user
    auth_hash = request.env["omniauth.auth"]
    handle_omniauth_authentication(auth_hash)
  end

  def failure
    log_omniauth_failure
    show_error I18n.t(:error_external_authentication_failed_message, message: omniauth_error)
  end

  private

  def log_omniauth_failure
    type = request.env["omniauth.error.type"] || "internal"
    logger.warn "OmniAuth authentication failed (Error #{type}): #{omniauth_error}"
  end

  def omniauth_error
    message = request.env["omniauth.error"] || request.env["omniauth.error.type"] || request.env["omniauth.error.message"]
    message&.to_s || "Unknown error"
  end

  def redirect_omniauth_register_modal(user, auth_hash)
    # Store a timestamp so we can later make sure that authentication information can
    # only be reused for a short time.
    session[:auth_source_registration] = auth_hash.merge(omniauth: true, timestamp: Time.current)
    @user = user
    render template: "/account/register"
  end

  # Avoid remembering the back_url if we're coming from the login page
  def remember_back_url?
    return false if omniauth_back_url.blank?

    account_routes = /\/(login|account)/
    omniauth_direct_login? || !omniauth_back_url.match?(account_routes)
  end

  # In case of SAML post bindings, we lose our session information
  # so we need to store it in the RelayState parameter
  def omniauth_back_url
    request.env["omniauth.origin"].presence || params[:RelayState]
  end

  def default_breadcrumb; end
end
