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

##
# Intended to be used by the ApplicationController to provide login/logout helpers
module Accounts::CurrentUser
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  protected

  # The current user is a per-session kind of thing and session stuff is controller responsibility.
  # A globally accessible User.current is a big code smell. When used incorrectly it allows getting
  # the current user outside of a session scope, i.e. in the model layer, from mailers or
  # in the console which doesn't make any sense. For model code that needs to be aware of the
  # current user, i.e. when returning all visible projects for <somebody>, the controller should
  # pass the current user to the model, instead of letting it fetch it by itself through
  # `User.current`. This method acts as a reminder and wants to encourage you to use it.
  # Project.visible_by actually allows the controller to pass in a user but it falls back
  # to `User.current` and there are other places in the session-unaware codebase,
  # that rely on `User.current`.
  def current_user
    User.current
  end

  def user_setup
    # Find the current user
    User.current = find_current_user
  end

  # check if login is globally required to access the application
  def check_if_login_required
    # no check needed if user is already logged in
    return true if current_user.logged?

    require_login if Setting.login_required?
  end

  # Returns the current user or nil if no user is logged in
  # and starts a session if needed
  def find_current_user
    %i[
      current_session_user
      current_autologin_user
      current_rss_key_user
      current_api_key_user
    ].each do |method|
      user = send(method)
      return user if user&.logged? && user&.active?
    end

    nil
  end

  def current_session_user
    return if session[:user_id].nil?

    User.active.find_by(id: session[:user_id])
  end

  def current_autologin_user
    return unless Setting::Autologin.enabled?

    autologin_cookie_name = OpenProject::Configuration["autologin_cookie_name"]
    autologin_token = cookies[autologin_cookie_name]
    return unless autologin_token

    user = User.try_to_autologin(autologin_token)

    if user
      login_user(user)
      user
    else
      cookies.delete(autologin_cookie_name)
      nil
    end
  end

  def current_rss_key_user
    if params[:format] == "atom" && params[:key] && accept_key_auth_actions.include?(params[:action])
      # RSS key authentication does not start a session
      User.find_by_rss_key(params[:key])
    end
  end

  def current_api_key_user
    return unless Setting.rest_api_enabled? && api_request?

    key = api_key_from_request

    if key && accept_key_auth_actions.include?(params[:action])
      # Use API key
      User.find_by_api_key(key)
    end
  end

  # Sets the logged in user
  def logged_user=(user)
    if user&.is_a?(User)
      login_user(user)
    else
      logout_user
    end
  end

  # Logout the current user
  def logout_user
    ::Users::LogoutService
      .new(controller: self)
      .call!(current_user)
  end

  # Redirect the user according to the logout scheme
  def perform_post_logout(prev_session, prev_user)
    # First, check if there is an SLO callback for a given
    # omniauth provider of the user
    provider = ::OpenProject::Plugins::AuthPlugin.login_provider_for(prev_user)
    if provider && (callback = provider[:single_sign_out_callback])
      instance_exec prev_session, prev_user, &callback
      return if performed?
    end

    # Otherwise, if there is an omniauth direct login
    # and we're not logging out globally, ensure the
    # user does not get re-logged in
    if Setting.login_required? && omniauth_direct_login?
      flash.now[:notice] = I18n.t :notice_logged_out
      render :exit, locals: { instructions: :after_logout }
      return
    end

    redirect_to(home_url) unless performed?
  end

  # Login the current user
  def login_user(user)
    ::Users::LoginService
      .new(user:, controller: self, request:)
      .call!
  end

  def require_login
    unless current_user.logged?

      respond_to do |format|
        format.any(:html, :atom) do
          # Ensure we reset the session to terminate any old session objects
          # but ONLY for html requests to avoid double-resetting sessions
          reset_session

          redirect_to main_app.signin_path(back_url: login_back_url)
        end

        auth_header = OpenProject::Authentication::WWWAuthenticate.response_header(request_headers: request.headers)

        format.any(:xml, :js, :json) do
          head :unauthorized,
               "X-Reason" => "login needed",
               "WWW-Authenticate" => auth_header
        end

        format.all { head :not_acceptable }
      end
      return false
    end
    true
  end

  def require_admin
    return unless require_login

    render_403 unless current_user.admin?
  end
end
