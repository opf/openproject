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

module FrontendAssetHelper
  CLI_DEFAULT_PROXY = 'http://localhost:4200'.freeze

  def self.assets_proxied?
    !Rails.env.production? && cli_proxy?
  end

  def self.cli_proxy
    ENV.fetch('OPENPROJECT_CLI_PROXY', CLI_DEFAULT_PROXY)
  end

  def self.cli_proxy?
    cli_proxy.present?
  end

  ##
  # Include angular CLI frontend assets by either referencing a prod build,
  # or referencing the running CLI proxy that hosts the assets in memory.
  def include_frontend_assets
    capture do
      %w(vendor.js polyfills.js runtime.js main.js).each do |file|
        concat javascript_include_tag variable_asset_path(file)
      end

      if FrontendAssetHelper.assets_proxied?
        concat javascript_include_tag variable_asset_path("styles.js")
      else
        concat stylesheet_link_tag variable_asset_path("styles.css")
      end
    end
  end

  private

  def angular_cli_asset(path)
    URI.join(FrontendAssetHelper.cli_proxy, "assets/frontend/#{path}")
  end

  def frontend_asset_path(unhashed, options = {})
    file_name = ::OpenProject::Assets.lookup_asset unhashed

    asset_path "assets/frontend/#{file_name}", options.merge(skip_pipeline: true)
  end

  def variable_asset_path(path)
    if FrontendAssetHelper.assets_proxied?
      angular_cli_asset(path)
    else
      frontend_asset_path(path)
    end
  end
end
