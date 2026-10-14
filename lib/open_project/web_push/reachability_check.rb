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
    PROBES = {
      "fcm.googleapis.com" => "https://fcm.googleapis.com/",
      "updates.push.services.mozilla.com" => "https://updates.push.services.mozilla.com/",
      "*.push.apple.com" => "https://web.push.apple.com/",
      "*.notify.windows.com" => "https://wns2-par02p.notify.windows.com/"
    }.freeze
    TIMEOUT = 3

    Result = Data.define(:host, :reachable, :reason, :code) do
      def reachable? = reachable
    end

    def self.call = new.call

    def call
      OpenProject::WebPush.push_service_host_patterns
        .map { |pattern| [pattern, *probe_target(pattern)] }
        .map { |pattern, url, sample| Thread.new { probe(pattern, url, sample) } }
        .map(&:value)
    end

    private

    def probe_target(pattern)
      sample_url = PROBES.fetch(pattern)
      return [sample_url, false] unless pattern.start_with?("*.")

      stored_host = stored_endpoint_host(pattern.delete_prefix("*"))
      stored_host ? ["https://#{stored_host}/", false] : [sample_url, true]
    end

    def stored_endpoint_host(suffix)
      like = "%#{PushSubscription.sanitize_sql_like(suffix)}/%"
      endpoint = PushSubscription.where("endpoint LIKE ?", like).pick(:endpoint)
      URI(endpoint).host if endpoint
    end

    def probe(pattern, url, sample)
      response = OpenProject::SsrfProtection.head(
        url,
        max_redirects: 0,
        allow_unfollowed_redirects: true,
        http_options: { open_timeout: TIMEOUT, read_timeout: TIMEOUT, write_timeout: TIMEOUT }
      )
      Result.new(host: pattern, reachable: true, reason: nil, code: response.code)
    rescue Timeout::Error
      unreachable(pattern, :timeout)
    rescue SsrfFilter::UnresolvedHostname
      unreachable(pattern, sample ? :sample_unresolved : :unresolved)
    rescue SsrfFilter::PrivateIPAddress
      unreachable(pattern, :private_address)
    rescue SsrfFilter::Error
      unreachable(pattern, :filtered)
    rescue OpenSSL::SSL::SSLError
      unreachable(pattern, :tls)
    rescue SystemCallError, SocketError, IOError, Net::ProtocolError, Net::HTTPBadResponse
      unreachable(pattern, :connection)
    end

    def unreachable(pattern, reason)
      Result.new(host: pattern, reachable: false, reason:, code: nil)
    end
  end
end
