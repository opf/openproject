#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

  ##
  # Include angular CLI frontend assets by either referencing a prod build,
  # or referencing the running CLI proxy that hosts the assets in memory.
  def include_frontend_assets
    capture do
      if Rails.env.production? || !frontend_assets_proxied?
        concat javascript_include_tag frontend_asset_path "vendor.js"
        concat javascript_include_tag frontend_asset_path "polyfills.js"
        concat javascript_include_tag frontend_asset_path "runtime.js"
        concat javascript_include_tag frontend_asset_path "main.js"
        concat stylesheet_link_tag frontend_asset_path "styles.css"
      else
        concat javascript_include_tag angular_cli_asset "vendor.js"
        concat javascript_include_tag angular_cli_asset "polyfills.js"
        concat javascript_include_tag angular_cli_asset "runtime.js"
        concat javascript_include_tag angular_cli_asset "main.js"
        concat javascript_include_tag angular_cli_asset "styles.js"
      end
    end
  end

  private

  def angular_cli_asset(path)
    base_url = ENV.fetch('OPENPROJECT_DEV_CLI_PROXY', 'http://localhost:4200')

    URI.join(base_url, path)
  end

  def frontend_assets_proxied?
    proxy_in_dev = Rails.env.development? && !ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_NO_CLI_PROXY'])
    proxy_in_test = Rails.env.test? && ActiveRecord::Type::Boolean.new.cast(ENV['OPENPROJECT_CLI_PROXY_IN_TEST'])

    proxy_in_dev || proxy_in_test
  end

  def frontend_asset_path(unhashed, options = {})
    file_name = ::OpenProject::Assets.lookup_asset unhashed

    asset_path "assets/frontend/#{file_name}", options.merge(skip_pipeline: true)
  end
end
