# frozen_string_literal: true

require "base64"

module TestManagement
  module CiConnections
    # "Check connection": one authenticated read of the repository / project with the stored
    # token, so admins see whether URL, repository and token fit together.
    #   GitHub: GET https://api.github.com/repos/:owner/:repo   (GHES: <base>/api/v3/repos/…)
    #   GitLab: GET <base>/api/v4/projects/:url-encoded-path
    #   Gitea / Forgejo / Codeberg: GET <base>/api/v1/repos/:owner/:repo  ("Authorization: token …")
    #   Jenkins: GET <job url>/api/json  (HTTP Basic user:API token)
    #   Woodpecker: GET <base>/api/repos/:repo_id  (Bearer personal token)
    # Stores check_status (ok | unauthorized | not_found | error), a short message and the time.
    # The token is only sent to the provider; it never appears in the message or logs.
    #
    # Self-hosted servers (0015): every URL is built below the connection's base URL (sub-paths
    # such as https://host/gitlab work), the connection's CA is trusted (CiConnections::Http), and
    # after a successful read the server version is probed and stored (server_version):
    #   GitLab: GET <base>/api/v4/metadata (falls back to /api/v4/version)
    #   Gitea / Forgejo / Codeberg: GET <base>/api/v1/version
    #   Jenkins: X-Jenkins header of the job response
    #   Woodpecker: GET <base>/version
    #   GitHub Enterprise Server: X-GitHub-Enterprise-Version header (github.com reports none)
    # A GitLab older than MIN_GITLAB_VERSION is reported in the message (merge-request diffs use
    # the deprecated /changes endpoint there). Blocked private addresses (SSRF protection) get a
    # message that names the allowlist variable and the addresses to allow.
    # Inbound-only connections are never called.
    class CheckService
      TIMEOUT_SECONDS = 10
      MIN_GITLAB_VERSION = "15.7"

      def initialize(user:, connection:)
        @user = user
        @connection = connection
      end

      def call
        return failure(:error_unauthorized) unless user.allowed_in_project?(:manage_test_ci, connection.project)
        return failure(:tm_ci_inbound_only) if connection.inbound_only?

        token = connection.decrypted_token
        return failure(:tm_ci_check_needs_token) if token.blank?
        return failure(:tm_ci_check_needs_username) if connection.jenkins? && connection.ci_username.blank?

        status, message, version = request(token)
        connection.update_columns(check_status: status, check_message: message&.first(500), checked_at: Time.current,
                                  server_version: version&.first(64))
        ServiceResult.success(result: connection)
      end

      # [url, how] of the version probe; how: :json (body "version") or a response header name.
      def version_probe
        base = connection.effective_base_url
        case connection.provider
        when "gitlab" then [["#{base}/api/v4/metadata", :json], ["#{base}/api/v4/version", :json]]
        when "gitea", "forgejo", "codeberg" then [["#{base}/api/v1/version", :json]]
        when "woodpecker" then [["#{base}/version", :json]]
        else []
        end
      end

      def url
        base = connection.effective_base_url
        case connection.provider
        when "github" then "#{self.class.github_api(base)}/repos/#{connection.repository}"
        when "gitlab" then "#{base}/api/v4/projects/#{ERB::Util.url_encode(connection.repository)}"
        when "jenkins" then "#{connection.jenkins_job_url}/api/json"
        when "woodpecker" then "#{base}/api/repos/#{connection.repository}"
        else "#{base}/api/v1/repos/#{connection.repository}"
        end
      end

      def headers(token)
        common = { "User-Agent" => "OpenProject-TestManagement", "Accept" => "application/json" }
        case connection.provider
        when "github" then common.merge("Authorization" => "Bearer #{token}", "Accept" => "application/vnd.github+json")
        when "gitlab" then common.merge("PRIVATE-TOKEN" => token)
        when "jenkins" then common.merge("Authorization" => self.class.basic_auth(connection.ci_username, token))
        when "woodpecker" then common.merge("Authorization" => "Bearer #{token}")
        else common.merge("Authorization" => "token #{token}")
        end
      end

      def self.github_api(base)
        base == CiConnection::DEFAULT_BASE_URLS["github"] ? "https://api.github.com" : "#{base}/api/v3"
      end

      def self.basic_auth(user, secret)
        "Basic #{Base64.strict_encode64("#{user}:#{secret}")}"
      end

      private

      attr_reader :user, :connection

      def http
        @http ||= Http.session(connection, timeout: TIMEOUT_SECONDS)
      end

      def request(token)
        response = http.get(url, headers: headers(token))
        return ["error", Http.describe(response.error, connection), nil] if Http.error_response?(response)

        status, message = classify(response.status.to_i)
        return [status, message, nil] unless status == "ok"

        version = header_version(response) || probe_version(token)
        [status, version_message(message, version), version]
      rescue StandardError => e
        ["error", Http.describe(e, connection), nil]
      end

      def header_version(response)
        name = case connection.provider
               when "jenkins" then "x-jenkins"
               when "github" then "x-github-enterprise-version"
               end
        return nil unless name

        value = response.headers[name]
        (value.is_a?(Array) ? value.first : value).presence&.to_s
      end

      # Best effort: a failing probe never changes the check result.
      def probe_version(token)
        version_probe.each_key do |probe_url|
          response = http.get(probe_url, headers: headers(token))
          next if Http.error_response?(response) || !response.status.to_i.between?(200, 299)

          version = parsed_version(response.body.to_s)
          return version if version
        end
        nil
      rescue StandardError
        nil
      end

      def parsed_version(body)
        parsed = JSON.parse(body)
        parsed.is_a?(Hash) ? parsed["version"].to_s.strip.presence : nil
      rescue JSON::ParserError
        nil
      end

      def version_message(message, version)
        return message if version.blank?

        parts = [message, I18n.t("test_management.project_settings.ci.server_version", version:)]
        if connection.gitlab? && outdated_gitlab?(version)
          parts << I18n.t("test_management.project_settings.ci.gitlab_outdated", min: MIN_GITLAB_VERSION)
        end
        parts.join(", ")
      end

      def outdated_gitlab?(version)
        number = version[/\A\d+(\.\d+)*/]
        number.present? && Gem::Version.new(number) < Gem::Version.new(MIN_GITLAB_VERSION)
      rescue ArgumentError
        false
      end

      def classify(code)
        case code
        when 200..299 then ["ok", "HTTP #{code}"]
        when 401, 403 then ["unauthorized", "HTTP #{code}"]
        when 404 then ["not_found", "HTTP #{code}"]
        else ["error", "HTTP #{code}"]
        end
      end

      def failure(error)
        connection.errors.add(:base, error)
        ServiceResult.failure(result: connection, errors: connection.errors)
      end
    end
  end
end
