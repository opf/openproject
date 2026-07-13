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

require "omniauth/openid_connect"
require "omniauth/openid_connect/providers"
require "open_project/openid_connect/engine"

module OpenProject
  module OpenIDConnect
    ACCESS_TOKEN_TYPE = "urn:ietf:params:oauth:token-type:access_token"
    TOKEN_EXCHANGE_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:token-exchange"

    def self.configuration
      providers = ::OpenIDConnect::Provider.where(available: true)

      OpenProject::ConfidentialCache.fetch(providers.cache_key_with_version) do
        providers.each_with_object({}) do |provider, hash|
          hash[provider.slug.to_sym] = provider.to_h
        end
      end
    end

    def self.providers
      # update base redirect URI in case settings changed
      ::OmniAuth::OpenIDConnect::Providers.configure(
        base_redirect_uri: "#{Setting.protocol}://#{Setting.host_name}#{OpenProject::Configuration['rails_relative_url_root']}"
      )

      configuration.map do |slug, configuration|
        provider = configuration.delete(:oidc_provider)
        clazz =
          case provider
          when "google"
            ::OmniAuth::OpenIDConnect::Google
          when "microsoft_entra"
            ::OmniAuth::OpenIDConnect::Azure
          else
            ::OmniAuth::OpenIDConnect::Provider
          end

        clazz.new(slug, configuration)
      end
    end
  end
end
