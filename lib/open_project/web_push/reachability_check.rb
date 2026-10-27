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

module OpenProject::WebPush
  class ReachabilityCheck
    # The apex of apple does not resolve, so a subdomain that answers stands in for it.
    KNOWN_SERVICES = {
      "fcm.googleapis.com" => "fcm.googleapis.com",
      "updates.push.services.mozilla.com" => "updates.push.services.mozilla.com",
      "push.apple.com" => "web.push.apple.com"
    }.freeze
    TIMEOUT = 3

    Result = Data.define(:host, :reachable, :reason, :code) do
      def reachable? = reachable
    end

    def self.call = new.call
    def self.hosts = new.hosts

    def hosts
      known = KNOWN_SERVICES.flat_map do |service, sample|
        stored_hosts.select { under?(it, service) }.presence || [sample]
      end
      known + stored_hosts.reject { |host| KNOWN_SERVICES.each_key.any? { under?(host, it) } }
    end

    def call
      threads = hosts.map do |host|
        Thread.new { Rails.application.executor.wrap { probe(host) } }
      end

      # Waiting on the probes while holding the load interlock would block a code reload,
      # and the reload would in turn block the probes from starting.
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads { threads.map(&:value) }
    end

    private

    def stored_hosts
      @stored_hosts ||= PushSubscription.endpoint_hosts
    end

    def under?(host, service)
      host == service || host.end_with?(".#{service}")
    end

    def sample?(host)
      KNOWN_SERVICES.any? { |service, sample| sample == host && service != host } && stored_hosts.exclude?(host)
    end

    def probe(host)
      response = OpenProject::SsrfProtection.head(
        URI::HTTPS.build(host:, path: "/").to_s,
        max_redirects: 0,
        allow_unfollowed_redirects: true,
        http_options: { open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT }
      )
      Result.new(host:, reachable: true, reason: nil, code: response.code)
    rescue Timeout::Error
      unreachable(host, :timeout)
    rescue SsrfFilter::UnresolvedHostname
      unreachable(host, sample?(host) ? :sample_unresolved : :unresolved)
    rescue SsrfFilter::PrivateIPAddress
      unreachable(host, :private_address)
    rescue SsrfFilter::Error
      unreachable(host, :filtered)
    rescue OpenSSL::SSL::SSLError
      unreachable(host, :tls)
    rescue SystemCallError, SocketError, IOError, Net::ProtocolError, Net::HTTPBadResponse
      unreachable(host, :connection)
    end

    def unreachable(host, reason)
      Result.new(host:, reachable: false, reason:, code: nil)
    end
  end
end
