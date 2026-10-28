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
    def initialize(base_url:, api_token:)
      @client = Client.new(base_url:, api_token:)
    end

    def call(errors)
      @client.projects(size: 1)
    rescue Client::SsrfError
      errors.add(:base_url, :ssrf_filtered, env_name: Settings::Definition[:ssrf_protection_ip_allowlist].env_name)
    rescue Client::TimeoutError
      errors.add(:base_url, :request_timed_out)
    rescue Client::SslError
      errors.add(:base_url, :ssl_error)
    rescue Client::InvalidUrlError
      errors.add(:base_url, :invalid_url)
    rescue Client::ConnectionError
      errors.add(:base_url, :cannot_be_connected_to)
    rescue Client::AuthenticationError
      errors.add(:api_token, :rejected)
    rescue Client::ResponseError
      errors.add(:base_url, :not_squashtm)
    end
  end
end
