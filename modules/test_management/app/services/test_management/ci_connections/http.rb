# frozen_string_literal: true

require "resolv"

module TestManagement
  module CiConnections
    # Outbound HTTP for one CI connection: "Check connection", "Run in CI" (Dispatchers) and the
    # Test Assistant's pull-request source all build their session here, so self-hosted options
    # apply everywhere:
    # * OpenProject.httpx – SSRF filter (private addresses need OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST),
    #   no redirects, OpenProject's httpx timeouts;
    # * the connection's ca_certificate is added to the system trust store (cert_store), so an
    #   internal CA works without touching the server's SSL_CERT_FILE. TLS verification is never
    #   switched off – there is deliberately no option for it.
    #
    # Errors become short, secret-free messages; a blocked private address explains the allowlist.
    module Http
      SSRF_ENV = "OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST"
      RESOLVE_TIMEOUT_SECONDS = 2

      module_function

      def session(connection, timeout:)
        session = OpenProject.httpx.with(timeout: { request_timeout: timeout })
        store = connection.ca_cert_store
        store ? session.with(ssl: { cert_store: store }) : session
      end

      def error_response?(response)
        defined?(::HTTPX::ErrorResponse) && response.is_a?(::HTTPX::ErrorResponse)
      end

      # Message for an exception raised by, or wrapped in, an HTTPX request.
      def describe(error, connection)
        if ssrf?(error)
          ssrf_message(connection)
        elsif tls?(error)
          I18n.t("test_management.project_settings.ci.errors.tls", host: host(connection),
                                                                   detail: error.message.to_s.first(200))
        else
          error.class.name.to_s.demodulize
        end
      end

      def ssrf?(error)
        names = [error.class.name, *error.class.ancestors.map(&:name)].compact
        names.any? { |name| name.end_with?("ServerSideRequestForgeryError") }
      end

      def tls?(error)
        error.is_a?(OpenSSL::SSL::SSLError) ||
          (defined?(::HTTPX::TLSError) && error.is_a?(::HTTPX::TLSError))
      end

      def ssrf_message(connection)
        host = host(connection)
        addresses = resolve(host)
        I18n.t("test_management.project_settings.ci.errors.ssrf",
               host:, env: SSRF_ENV,
               addresses: addresses.any? ? addresses.join(", ") : I18n.t("test_management.project_settings.ci.errors.ssrf_unresolved"))
      end

      def host(connection)
        URI.parse(connection.effective_base_url).host.to_s
      rescue URI::InvalidURIError
        ""
      end

      # The addresses the administrator has to allow (IPs or CIDRs only; hostnames are not accepted).
      def resolve(host)
        return [] if host.blank?
        return [host] if host.match?(Resolv::IPv4::Regex) || host.match?(Resolv::IPv6::Regex)

        Timeout.timeout(RESOLVE_TIMEOUT_SECONDS) { Resolv.getaddresses(host).uniq.first(4) }
      rescue StandardError # incl. Timeout::Error
        []
      end
    end
  end
end
