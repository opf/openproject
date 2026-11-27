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

require "recaptcha"
require "net/http"

module ::Recaptcha
  class RequestController < ApplicationController
    # Include global layout helper
    layout "no_menu"

    # User is not yet logged in, so skip login required check
    skip_before_action :check_if_login_required
    no_authorization_required! :perform,
                               :verify

    # Skip if recaptcha was disabled
    before_action :skip_if_disabled

    # Require authenticated user from the core to be present
    before_action :require_authenticated_user

    # Skip if user is admin
    before_action :skip_if_admin

    # Skip if user has confirmed already
    before_action :skip_if_user_verified

    # Ensure we set the correct configuration for rendering/verifying the captcha
    around_action :set_captcha_settings

    ##
    # Request verification form
    def perform
      if OpenProject::Recaptcha::Configuration.use_hcaptcha?
        allow_captcha_service(:hcaptcha)
      elsif OpenProject::Recaptcha::Configuration.use_turnstile?
        allow_captcha_service(:turnstile)
      elsif OpenProject::Recaptcha::Configuration.use_recaptcha?
        allow_captcha_service(:recaptcha)
      end
    end

    def verify
      if valid_turnstile? || valid_recaptcha?
        save_recaptcha_verification_success!
        complete_stage_redirect
      else
        fail_recaptcha I18n.t("recaptcha.error_captcha")
      end
    end

    private

    def set_captcha_settings(&)
      if OpenProject::Recaptcha::Configuration.use_hcaptcha?
        Recaptcha.with_configuration(verify_url: OpenProject::Recaptcha.hcaptcha_verify_url,
                                     api_server_url: OpenProject::Recaptcha.hcaptcha_api_server_url,
                                     &)
      else
        yield
      end
    end

    ##
    # Insert that the account was verified
    def save_recaptcha_verification_success!
      # Remove all previous
      ::Recaptcha::Entry.where(user_id: @authenticated_user.id).delete_all
      ::Recaptcha::Entry.create!(user_id: @authenticated_user.id, version: recaptcha_version)
    end

    def recaptcha_version
      case recaptcha_settings["recaptcha_type"]
      when ::OpenProject::Recaptcha::TYPE_DISABLED
        0
      when ::OpenProject::Recaptcha::TYPE_V2, ::OpenProject::Recaptcha::TYPE_HCAPTCHA
        2
      when ::OpenProject::Recaptcha::TYPE_V3
        3
      when ::OpenProject::Recaptcha::TYPE_TURNSTILE
        99 # Turnstile is not comparable/compatible with recaptcha
      end
    end

    ##
    #
    def valid_recaptcha?
      call_args = { secret_key: recaptcha_settings["secret_key"] }
      if recaptcha_version == 3
        call_args[:action] = "login"
      end

      verify_recaptcha call_args
    end

    ##
    #
    def valid_turnstile?
      return false unless OpenProject::Recaptcha::Configuration.use_turnstile?
      token = params["turnstile-response"]
      return false if token.blank?

      data = {
        "response" => token,
        "remoteip" => request.remote_ip,
        "secret" => recaptcha_settings["secret_key"],
      }

      data_encoded = URI.encode_www_form(data)

      response = Net::HTTP.post_form(
        URI("https://challenges.cloudflare.com/turnstile/v0/siteverify"),
        data
      )
      response = JSON.parse(response.body)
      response["success"]
    end

    ##
    # fail the recaptcha
    def fail_recaptcha(msg)
      flash[:error] = msg
      failure_stage_redirect
    end

    ##
    # Ensure the authentication stage from the core provided the authenticated user
    def require_authenticated_user
      @authenticated_user = User.find(session[:authenticated_user_id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Failed to find authenticated_user for recaptcha verify."
      failure_stage_redirect
    end

    def recaptcha_settings
      Setting.plugin_openproject_recaptcha
    end

    def skip_if_disabled
      if recaptcha_settings["recaptcha_type"] == ::OpenProject::Recaptcha::TYPE_DISABLED
        complete_stage_redirect
      end
    end

    def skip_if_admin
      if @authenticated_user&.admin?
        complete_stage_redirect
      end
    end

    def skip_if_user_verified
      if ::Recaptcha::Entry.exists?(user_id: @authenticated_user.id)
        Rails.logger.debug { "User #{@authenticated_user.id} already provided recaptcha. Skipping. " }
        complete_stage_redirect
      end
    end

    ##
    # Complete this authentication step and return to core
    # logging in the user
    def complete_stage_redirect
      redirect_to authentication_stage_complete_path :recaptcha
    end

    def failure_stage_redirect
      redirect_to authentication_stage_failure_path :recaptcha
    end

    ##
    # Add CAPTCHA service CSP rules
    def allow_captcha_service(service_type)
      case service_type.to_sym
      when :recaptcha
        append_content_security_policy_directives(
          frame_src: %w[https://www.recaptcha.net/recaptcha/ https://www.gstatic.com/recaptcha/]
        )
      when :hcaptcha
        sources = %w[https://*.hcaptcha.com]
        append_content_security_policy_directives(
          frame_src: sources,
          script_src: sources,
          style_src: sources,
          connect_src: sources
        )
      when :turnstile
        sources = %w[https://challenges.cloudflare.com]
        append_content_security_policy_directives(
          frame_src: sources,
          style_src: sources,
          connect_src: sources
        )
      end
    end
  end
end
