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

module SquashTMIntegration
  class ConnectionCheck
    MINIMUM_VERSION = Gem::Version.new("15.0.2")

    def initialize(base_url:, api_token:)
      @base_url = base_url
      @client = Client.new(base_url:, api_token:)
    end

    def call(errors)
      @client.projects(size: 1)
      check_version(errors)
    rescue Client::SsrfError
      errors.add(:base, :base_url_ssrf_filtered, url: @base_url, env_name: Settings::Definition[:ssrf_protection_ip_allowlist].env_name)
    rescue Client::TimeoutError
      errors.add(:base, :base_url_request_timed_out, url: @base_url)
    rescue Client::SslError
      errors.add(:base, :base_url_ssl_error, url: @base_url)
    rescue Client::InvalidUrlError
      errors.add(:base, :base_url_invalid, url: @base_url)
    rescue Client::ConnectionError
      errors.add(:base, :base_url_cannot_be_connected_to, url: @base_url)
    rescue Client::AuthenticationError
      errors.add(:base, :api_token_rejected)
    rescue Client::ServerError => e
      errors.add(:base, :base_url_server_error, url: @base_url, status: e.status)
    rescue Client::UnexpectedStatusError, Client::InvalidResponseError
      errors.add(:base, :base_url_not_squashtm, url: @base_url)
    end

    private

    def check_version(errors)
      version = installed_version
      return if version && version >= MINIMUM_VERSION

      errors.add(:base, :squashtm_version_unsupported, version: version || "unknown", minimum: MINIMUM_VERSION)
    end

    def installed_version
      number = @client.version.to_s[/\A\d+(\.\d+)*/]
      number && Gem::Version.new(number)
    rescue Client::NotFoundError, Client::InvalidResponseError
      nil
    end
  end
end
