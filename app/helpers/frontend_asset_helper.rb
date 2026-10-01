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

module FrontendAssetHelper
  CLI_DEFAULT_PROXY = begin
    host = ENV.fetch("FE_HOST", "localhost")
    port = ENV.fetch("FE_PORT", 4200)
    "http://#{host}:#{port}"
  end
  CLI_PROXY = ENV.fetch("OPENPROJECT_CLI_PROXY", CLI_DEFAULT_PROXY)

  def self.assets_proxied?
    ENV["OPENPROJECT_DISABLE_DEV_ASSET_PROXY"].blank? && !Rails.env.production? && cli_proxy.present?
  end

  def self.cli_proxy
    CLI_PROXY
  end

  ##
  # Include angular CLI frontend assets by either referencing a prod build,
  # or referencing the running CLI proxy that hosts the assets in memory.
  def include_frontend_assets
    capture do
      %w(polyfills.js main.js).each do |file|
        concat nonced_javascript_include_tag variable_asset_path(file), skip_pipeline: true, type: "module"
      end

      concat frontend_stylesheet_link_tag("styles.css")
    end
  end

  def include_spot_assets
    capture do
      concat frontend_stylesheet_link_tag("spot.css")
    end
  end

  def frontend_stylesheet_link_tag(path)
    stylesheet_link_tag variable_asset_path(path), media: :all, skip_pipeline: true
  end

  def nonced_javascript_include_tag(path, **)
    javascript_include_tag(path, nonce: content_security_policy_nonce, **)
  end

  def variable_asset_path(path)
    if FrontendAssetHelper.assets_proxied?
      File.join(
        FrontendAssetHelper.cli_proxy,
        Rails.application.config.relative_url_root,
        frontend_asset_path(path)
      )
    else
      # we do not need to take care about Rails.application.config.relative_url_root
      # because in this case javascript|stylesheet_include_tag will add it automatically.
      lookup_frontend_asset(path)
    end
  end

  ##
  # Like variable_asset_path, but for callers that use the resulting URL directly
  # (e.g. as a raw <link href> inside a shadow DOM, as BlockNote does) instead of
  # passing it through stylesheet_link_tag/javascript_include_tag. Those tag helpers
  # add relative_url_root automatically; direct consumers don't go through them, so
  # it must be prepended here instead. Do NOT use variable_asset_path itself for this:
  # it's shared with the tag-helper call sites, and prepending relative_url_root there
  # too would cause it to be applied twice for those (Rails' own idempotency guard in
  # compute_asset_path only catches an exact-prefix match, not one where relative_url_root
  # has a trailing slash).
  def raw_variable_asset_path(path)
    base_path = variable_asset_path(path)
    return base_path if FrontendAssetHelper.assets_proxied?

    File.join(Rails.application.config.relative_url_root.to_s, base_path)
  end

  private

  def lookup_frontend_asset(unhashed_file_name)
    hashed_file_name = ::OpenProject::Assets.lookup_asset(unhashed_file_name)
    frontend_asset_path(hashed_file_name)
  end

  def frontend_asset_path(file_name)
    "/assets/frontend/#{file_name}"
  end
end
