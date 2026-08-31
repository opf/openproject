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

module OpenProject
  class SsrfProtection < ::SsrfFilter
    class << self
      ##
      # Performs an SSRF-safe HTTP POST request to the given URL.
      #
      # Resolves the hostname and blocks requests to private/reserved IP ranges
      # (loopback, link-local, RFC 1918, etc.) to prevent server-side request forgery.
      # Use OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST to explicitly permit specific private IPs.
      #
      # @param url [String, URI] The URL to POST to (must use http or https)
      # @param options [Hash] Request options
      # @option options [String] :body Request body to send
      # @option options [Hash] :headers Additional HTTP headers, e.g. { "Content-Type" => "application/json" }
      # @option options [Hash] :params Query parameters to merge into the URL
      # @option options [Array<String>] :scheme_whitelist Allowed URI schemes (default: ["http", "https"])
      # @option options [Integer] :max_redirects Maximum number of redirects to follow (default: 10)
      # @option options [Hash] :http_options Options passed directly to Net::HTTP.start (e.g. read_timeout:, open_timeout:)
      # @option options [Proc] :resolver Custom DNS resolver; receives a hostname and returns an array of IPAddr objects
      # @yield [Net::HTTPResponse] Optional block to handle response object
      # @return [Net::HTTPResponse] The HTTP response
      # @raise [SsrfFilter::InvalidUriScheme] If the URI scheme is not in the whitelist
      # @raise [SsrfFilter::UnresolvedHostname] If the hostname cannot be resolved
      # @raise [SsrfFilter::PrivateIPAddress] If all resolved IPs are private/blocked
      # @raise [SsrfFilter::CRLFInjection] If CRLF characters are detected in headers
      # @raise [SsrfFilter::TooManyRedirects] If the redirect limit is exceeded (not possible with the default of 0)
      #
      # Redirects are disabled by default (max_redirects: 0). Following a redirect
      # on a POST is almost always wrong: SsrfFilter (which we inherit from) re-POSTs the full body to the redirect target
      # regardless of the redirect status code, which can leak the payload to an unintended server.
      # RFC 7231 only requires re-posting on 307/308; 301/302 should switch to GET. Override
      # max_redirects only if you fully understand the implications.
      #
      # @example Simple JSON POST
      #   response = OpenProject::SsrfProtection.post(
      #     "https://example.com/api/hook",
      #     headers: { "Content-Type" => "application/json" },
      #     body: { event: "updated" }.to_json
      #   )
      #
      # @example POST with custom timeout
      #   response = OpenProject::SsrfProtection.post(
      #     "https://example.com/notify",
      #     body: payload,
      #     http_options: { open_timeout: 5, read_timeout: 10 }
      #   )
      def post(url, options = {}, &)
        super(url, { max_redirects: 0, resolver: resolver }.merge(options), &)
      end

      ##
      # Performs an SSRF-safe HTTP GET request to the given URL.
      #
      # Resolves the hostname and blocks requests to private/reserved IP ranges
      # (loopback, link-local, RFC 1918, etc.) to prevent server-side request forgery.
      # Use OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST to explicitly permit specific private IPs.
      #
      # @param url [String, URI] The URL to GET from (must use http or https)
      # @param options [Hash] Request options
      # @option options [Hash] :headers Additional HTTP headers, e.g. { "Authorization" => "Bearer token" }
      # @option options [Hash] :params Query parameters to merge into the URL
      # @option options [Array<String>] :scheme_whitelist Allowed URI schemes (default: ["http", "https"])
      # @option options [Integer] :max_redirects Maximum number of redirects to follow (default: 10)
      # @option options [Hash] :http_options Options passed directly to Net::HTTP.start (e.g. read_timeout:, open_timeout:)
      # @option options [Proc] :resolver Custom DNS resolver; receives a hostname and returns an array of IPAddr objects
      # @yield [Net::HTTPResponse] Optional block to handle response object
      # @return [Net::HTTPResponse] The HTTP response
      # @raise [SsrfFilter::InvalidUriScheme] If the URI scheme is not in the whitelist
      # @raise [SsrfFilter::UnresolvedHostname] If the hostname cannot be resolved
      # @raise [SsrfFilter::PrivateIPAddress] If all resolved IPs are private/blocked
      # @raise [SsrfFilter::CRLFInjection] If CRLF characters are detected in headers
      # @raise [SsrfFilter::TooManyRedirects] If the redirect limit is exceeded
      #
      # @example Simple GET with authorization
      #   response = OpenProject::SsrfProtection.get(
      #     "https://example.com/api/data",
      #     headers: { "Authorization" => "Bearer token123" }
      #   )
      #
      # @example GET with custom timeout
      #   response = OpenProject::SsrfProtection.get(
      #     "https://example.com/api/resource",
      #     http_options: { open_timeout: 5, read_timeout: 10 }
      #   )
      #
      # @example GET with streamed response
      #   response = OpenProject::SsrfProtection.get(
      #     "https://example.com/api/resource",
      #     http_options: { open_timeout: 5, read_timeout: 10 }
      #   ) do |response|
      #     response.read_body do |chunk|
      #       print chunk
      #     end
      #   end
      def get(url, options = {}, &)
        super(url, { resolver: resolver }.merge(options), &)
      end

      ##
      # Given a hostname or IP address, returns the first one which is safe to use
      # for triggering a user initiated request.
      #
      # By default, private IP addresses are deemed not safe in the context of SSRF protection.
      # Use OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST to allow specific private IPs anyway.
      #
      # @param hostname_or_ip_address [String] The hostname (e.g. localhost) or IP address (e.g. 127.0.0.1) to check
      # @return [IPAddr] The first safe IP address which can be used for a request, or `nil` if there aren't any
      def safe_ip?(hostname_or_ip_address)
        if hostname_or_ip_address.is_a? IPAddr
          safe_ip_address hostname_or_ip_address
        elsif [Resolv::IPv4::Regex, Resolv::IPv6::Regex].any? { |regex| hostname_or_ip_address =~ regex }
          safe_ip_address IPAddr.new(hostname_or_ip_address)
        else
          safe_ip_address_for_hostname hostname_or_ip_address
        end
      end

      def safe_ip_address_for_hostname(hostname)
        ip_addresses = resolver.call hostname

        ip_addresses.find { |addr| safe_ip_address addr }
      end

      def safe_ip_address(ip_address)
        ip_address if !unsafe_ip_address?(ip_address)
      end

      def allowed_ip_address?(ip_address)
        OpenProject::Configuration.ssrf_protection_ip_allowlist.any? { |addr| addr.include? ip_address }
      end

      def resolver
        SsrfFilter::DEFAULT_RESOLVER
      end

      private

      def unsafe_ip_address?(ip_address)
        return false if allowed_ip_address?(ip_address)

        super
      end
    end
  end
end
