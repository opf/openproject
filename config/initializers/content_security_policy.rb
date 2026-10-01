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

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# rubocop:disable Lint/PercentStringArray
Rails.application.config.after_initialize do
  Rails.application.configure do
    config.content_security_policy do |policy|
      # Valid for assets
      assets_src = ["'self'"]
      asset_host = OpenProject::Configuration.rails_asset_host
      assets_src << asset_host if asset_host.present?

      # Valid for iframes
      frame_src = []
      frame_src << OpenProject::Configuration[:security_badge_url] if OpenProject::Configuration[:security_badge_displayed]

      # Default src
      default_src = %w('self') # rubocop:disable Lint/PercentStringArray

      # Attachment uploaders
      default_src += OpenProject::Configuration.remote_storage_hosts

      # Chargebee self-service
      chargebee_src = ["https://*.chargebee.com"]

      assets_src += chargebee_src
      frame_src += chargebee_src
      default_src += chargebee_src

      # Allow requests to CLI in dev mode
      connect_src = default_src + [OpenProject::Configuration.enterprise_trial_creation_host]

      # Allow connections to asset host for source maps
      connect_src << asset_host if asset_host.present?

      # Rules for media (e.g. video sources)
      media_src = default_src
      media_src << asset_host if asset_host.present?
      # Getting started video
      onboarding = Addressable::URI.parse(OpenProject::Static::Links.url_for(:onboarding_video_url))
      media_src << "#{onboarding.scheme}://#{onboarding.host}"
      enterprise_video = Addressable::URI.parse(OpenProject::Static::Links.url_for(:enterprise_welcome_video))
      media_src << "#{enterprise_video.scheme}://#{enterprise_video.host}"
      media_src.uniq!

      if OpenProject::Configuration.appsignal_frontend_key
        connect_src += ["https://appsignal-endpoint.net"]
      end

      # Add proxy configuration for Angular CLI to csp
      if FrontendAssetHelper.assets_proxied?
        proxied = ["ws://#{Setting.host_name}", "http://#{Setting.host_name}",
                   FrontendAssetHelper.cli_proxy.sub("http", "ws"), FrontendAssetHelper.cli_proxy]
        connect_src += proxied
        assets_src += proxied
        media_src += proxied
      end

      # Allow to extend the script-src in specific situations
      script_src = assets_src + %w(js.chargebee.com)

      # Allow unsafe-eval for rack-mini-profiler
      if Rails.env.development? && ENV.fetch("OPENPROJECT_RACK_PROFILER_ENABLED", false)
        script_src += %w('unsafe-eval') # rubocop:disable Lint/PercentStringArray
      end

      # Allow ANDI bookmarklet to run in development mode
      # https://www.ssa.gov/accessibility/andi/help/install.html
      if Rails.env.development?
        script_src += ["https://www.ssa.gov"]
        assets_src += ["https://www.ssa.gov"]
      end

      form_action = default_src

      # Allow test s3 bucket for direct uploads in tests
      if Rails.env.test?
        connect_src += ["test-bucket.s3.amazonaws.com"]
        form_action += ["test-bucket.s3.amazonaws.com"]
      end

      # Allow connections to S3 for BIM
      if OpenProject::Configuration.fog_directory.present?
        connect_src += [OpenProject::Configuration.fog_s3_upload_host]
        form_action += [OpenProject::Configuration.fog_s3_upload_host]
      end

      # Configure CSP directives
      policy.default_src(*default_src)
      policy.base_uri("'self'")
      policy.font_src(*assets_src, "data:")
      policy.form_action(*form_action)
      policy.frame_src(*frame_src, "'self'")
      policy.frame_ancestors("'self'")
      img_src = %w('self') + Array(OpenProject::Configuration.csp_img_src)
      img_src << asset_host if asset_host.present?
      policy.img_src(*img_src.compact.uniq)
      policy.script_src(*script_src)
      policy.script_src_attr("'none'")
      policy.style_src(*assets_src, "'unsafe-inline'")
      policy.object_src(OpenProject::Configuration[:security_badge_url])
      policy.connect_src(*connect_src)
      policy.media_src(*media_src)
    end

    # Generate session nonces for permitted importmap, inline scripts, and inline styles.
    # This handles Turbo integration natively
    config.content_security_policy_nonce_generator = lambda do |request|
      # Use Turbo nonce if available (for Turbo navigation)
      if request.env["HTTP_TURBO_REFERRER"].present? && request.env["HTTP_X_TURBO_NONCE"].present?
        request.env["HTTP_X_TURBO_NONCE"]
      else
        # Generate a new nonce based on session
        SecureRandom.base64(16)
      end
    end

    config.content_security_policy_nonce_directives = %w(script-src)
  end
end
# rubocop:enable Lint/PercentStringArray
