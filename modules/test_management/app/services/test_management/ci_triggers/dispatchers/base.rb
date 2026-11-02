# frozen_string_literal: true

require "base64"

module TestManagement
  module CiTriggers
    module Dispatchers
      # Sends the trigger request to the CI provider (see docs/ci/README.md, "Run in CI").
      # All requests go through OpenProject.httpx (SSRF filter, no redirects) with the
      # connection's own CA (CiConnections::Http). Secrets are only sent to the provider; they
      # never appear in results, errors or logs. Inbound-only connections get Manual, which
      # sends nothing.
      class Base
        TIMEOUT_SECONDS = 15
        USER_AGENT = "OpenProject-TestManagement"

        Result = Struct.new(:status, :url, :external_id, :error, keyword_init: true) do
          def triggered? = status == "triggered"
        end

        class RequestFailed < StandardError; end

        def self.for(connection)
          return Manual.new(connection:) if connection.inbound_only?

          case connection.provider
          when "github" then Github
          when "gitlab" then Gitlab
          when "jenkins" then Jenkins
          when "gitea" then Gitea
          when "forgejo", "codeberg" then Forgejo
          when "woodpecker" then Woodpecker
          else raise ArgumentError, "unknown CI provider #{connection.provider.inspect}"
          end.new(connection:)
        end

        def initialize(connection:)
          @connection = connection
        end

        # inputs: { "op_run_id" => "12", "op_iteration_id" => "34", "op_project" => "demo", "op_grep" => "…" }
        def call(ref:, inputs:)
          dispatch(ref:, inputs: inputs.transform_keys(&:to_s).transform_values(&:to_s))
        rescue RequestFailed => e
          failed(e.message)
        rescue StandardError => e
          failed(CiConnections::Http.describe(e, connection))
        end

        protected

        attr_reader :connection

        def dispatch(**) = raise(TestManagement::AbstractMethodError)

        def base_url = connection.effective_base_url
        def repository = connection.repository
        def token = connection.decrypted_token
        def enc(value) = ERB::Util.url_encode(value.to_s)

        # GitLab / Jenkins / Woodpecker style: OP_RUN_ID, OP_ITERATION_ID, OP_PROJECT, OP_GREP
        def variables(inputs) = inputs.transform_keys(&:upcase)

        def http
          @http ||= CiConnections::Http.session(connection, timeout: TIMEOUT_SECONDS)
        end

        def post(url, headers: {}, json: nil, form: nil)
          options = { headers: default_headers.merge(headers) }
          options[:json] = json unless json.nil?
          options[:form] = form unless form.nil?
          checked(http.post(url, **options))
        end

        def get(url, headers: {})
          checked(http.get(url, headers: default_headers.merge(headers)))
        end

        def default_headers
          { "User-Agent" => USER_AGENT, "Accept" => "application/json" }
        end

        def basic_auth(user, secret)
          "Basic #{Base64.strict_encode64("#{user}:#{secret}")}"
        end

        def checked(response)
          if CiConnections::Http.error_response?(response)
            raise RequestFailed, CiConnections::Http.describe(response.error, connection)
          end

          response
        end

        def code(response) = response.status.to_i

        def json(response)
          parsed = JSON.parse(response.body.to_s)
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end

        def header(response, name)
          value = response.headers[name]
          value.is_a?(Array) ? value.first : value
        end

        def triggered(url: nil, external_id: nil)
          Result.new(status: "triggered", url: safe_url(url), external_id: external_id&.to_s&.first(255))
        end

        def failed(message)
          Result.new(status: "failed", error: scrub(message.to_s).first(500))
        end

        # "HTTP 422: Unexpected inputs provided" – the provider's message, without secrets.
        def http_failure(response)
          body = json(response)
          detail = body["message"] || body["error"] || body["errors"]
          detail = detail.join(", ") if detail.is_a?(Array)
          failed(["HTTP #{code(response)}", detail.is_a?(String) ? detail.first(300) : nil].compact.join(": "))
        end

        def secrets
          [connection.decrypted_token, connection.decrypted_trigger_token].compact_blank
        end

        def scrub(text)
          secrets.reduce(text) { |memo, secret| memo.gsub(secret, "[FILTERED]") }
        end

        def safe_url(url)
          url = url.to_s
          url.match?(%r{\Ahttps?://}i) ? url.first(1024) : nil
        end
      end
    end
  end
end
