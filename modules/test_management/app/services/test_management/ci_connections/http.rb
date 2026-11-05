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

require "resolv"

module TestManagement
  module CiConnections
    module Http
      SSRF_ENV = "OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST"
      RESOLVE_TIMEOUT_SECONDS = 2

      module_function

      def session(timeout:)
        OpenProject.httpx.with(timeout: { request_timeout: timeout })
      end

      def error_response?(response)
        defined?(::HTTPX::ErrorResponse) && response.is_a?(::HTTPX::ErrorResponse)
      end

      def describe(error, connection)
        ssrf?(error) ? ssrf_message(connection) : error.class.name.to_s.demodulize
      end

      def ssrf?(error)
        names = [error.class.name, *error.class.ancestors.map(&:name)].compact
        names.any? { |name| name.end_with?("ServerSideRequestForgeryError") }
      end

      def tls?(error)
        names = [error.class.name, *error.class.ancestors.map(&:name)].compact
        names.any? { |name| name.match?(/SSL|TLS|Certificate/i) }
      end

      def ssrf_message(connection)
        host = host(connection)
        addresses = resolve(host)
        unresolved = I18n.t("test_management.project_settings.ci.errors.ssrf_unresolved")
        I18n.t("test_management.project_settings.ci.errors.ssrf",
               host:, env: SSRF_ENV,
               addresses: addresses.any? ? addresses.join(", ") : unresolved)
      end

      def host(connection)
        URI.parse(connection.effective_base_url).host.to_s
      rescue URI::InvalidURIError
        ""
      end

      def resolve(host)
        return [] if host.blank?
        return [host] if host.match?(Resolv::IPv4::Regex) || host.match?(Resolv::IPv6::Regex)

        Timeout.timeout(RESOLVE_TIMEOUT_SECONDS) { Resolv.getaddresses(host).uniq.first(4) }
      rescue StandardError
        []
      end
    end
  end
end
