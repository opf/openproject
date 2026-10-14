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
    SAMPLE_HOSTS = { "notify.windows.com" => "wns2-par02p.notify.windows.com" }.freeze
    TIMEOUT = 3

    Result = Data.define(:host, :reachable, :reason, :code) do
      def reachable? = reachable
    end

    def self.call = new.call

    def call
      OpenProject::WebPush.push_service_hosts
        .map { |host| [host, *probe_target(host)] }
        .map { |host, url, sample| Thread.new { probe(host, url, sample) } }
        .map(&:value)
    end

    private

    def probe_target(host)
      stored_host = stored_endpoint_host(host)
      return ["https://#{stored_host}/", false] if stored_host

      sample_host = SAMPLE_HOSTS[host]
      ["https://#{sample_host || host}/", sample_host.present?]
    end

    def stored_endpoint_host(host)
      authority = "^https://([^/]+\\.)?#{host.gsub('.', '\\.')}/"
      endpoint = PushSubscription.where("endpoint ~ ?", authority).order(:id).pick(:endpoint)
      URI(endpoint).host if endpoint
    end

    def probe(host, url, sample)
      response = OpenProject::SsrfProtection.head(
        url,
        max_redirects: 0,
        allow_unfollowed_redirects: true,
        http_options: { open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT }
      )
      Result.new(host:, reachable: true, reason: nil, code: response.code)
    rescue Timeout::Error
      unreachable(host, :timeout)
    rescue SsrfFilter::UnresolvedHostname
      unreachable(host, sample ? :sample_unresolved : :unresolved)
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
