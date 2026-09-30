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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Users
  class LoginService
    attr_accessor :controller, :request, :browser, :user, :cookies

    delegate :session, to: :controller

    def initialize(user:, controller:, request:)
      self.user = user
      self.controller = controller
      self.request = request
      self.browser = controller.send(:browser)
      self.cookies = controller.send(:cookies)
    end

    def call!
      autologin_requested = session.delete(:autologin_requested)
      autologin_token_id = session.delete(:autologin_token_id)
      retain_session_values do
        reset_session!

        User.current = user

        set_autologin_cookie if autologin_requested
        assign_autologin_session(autologin_token_id) if autologin_token_id.present?
      end

      successful_login
    end

    private

    def set_autologin_cookie
      return unless Setting::Autologin.enabled?

      # generate a key and set cookie if autologin
      token = Token::AutoLogin.create!(user:, data: token_session_information)
      cookie_options = {
        value: token.plain_value,
        # The autologin expiration is checked on validating the token
        # but still expire the cookie to avoid unnecessary retries
        expires: token.expires_on,
        path: OpenProject::Configuration["autologin_cookie_path"],
        secure: OpenProject::Configuration.https?,
        httponly: true
      }
      cookies[OpenProject::Configuration["autologin_cookie_name"]] = cookie_options

      # Tie the current session to this autologin token already
      assign_autologin_session(token.id)
    end

    def assign_autologin_session(token_id)
      session_id = ::Sessions::UserSession.where(session_id: session.id.private_id).pick(:id)
      ::Sessions::AutologinSessionLink.create!(token_id:, session_id:)
    end

    def successful_login
      user.log_successful_login

      # Clear all previous recovery tokens as user successfully logged in
      # We do not want to clear invitation tokens, as user might just be logging in with one
      Users::DropTokensService
        .new(current_user: user)
        .call!(clear_invitation_tokens: false)

      context = { user:, request:, session: }
      OpenProject::Hook.call_hook(:user_logged_in, context)
    end

    def reset_session!
      ::Sessions::DropAllSessionsService.call!(user) if drop_old_sessions?
      controller.reset_session
    end

    def retain_session_values
      # retain flash values
      flash_values = controller.flash.to_h

      # retain session values
      retained_session = retained_session_values || {}

      yield

      flash_values.each { |k, v| controller.flash[k] = v }

      session.merge!(retained_session)
      session.merge!(session_identification)
      apply_default_values(session)
    end

    def apply_default_values(session)
      session[:user_id] = user.id
      session[:updated_at] = Time.zone.now
    end

    def session_identification
      {
        platform: browser.platform&.name,
        browser: browser.name,
        browser_version: browser.version
      }
    end

    def token_session_information
      session_identification.merge(session_id: session.id)
    end

    def retained_session_values
      controller
        .session
        .to_h
        .with_indifferent_access
        .slice *(default_retained_keys + omniauth_provider_keys)
    end

    def omniauth_provider_keys
      provider_name = session[:omniauth_provider]
      return [] unless provider_name

      provider = ::OpenProject::Plugins::AuthPlugin.find_provider_by_name(provider_name)
      return [] unless provider && provider[:retain_from_session]

      provider[:retain_from_session]
    end

    def default_retained_keys
      %w[omniauth_provider user_from_auth_header autologin_token_id]
    end

    ##
    # We can only drop old sessions if they're stored in the database
    # and enabled by configuration.
    def drop_old_sessions?
      OpenProject::Configuration.drop_old_sessions_on_login?
    end
  end
end
