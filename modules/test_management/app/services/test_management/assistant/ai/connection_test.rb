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

module TestManagement
  module Assistant
    module AI
      class ConnectionTest
        TIMEOUT = 10
        CONNECT_TIMEOUT = 5
        MAX_BYTES = 5_000_000
        MAX_MODELS = 1000
        VERIFY_MAX_TOKENS = 16
        VERIFY_PROMPT = "Reply with OK."

        NON_CHAT = /embed|whisper|tts|dall-e|davinci|babbage|moderation|audio|realtime|transcribe|
                    image|imagine|video|search|sora|computer-use|rerank|ocr/x

        Result = Struct.new(:ok, :models, :error_kind, :message, :listed, :scope, keyword_init: true) do
          def ok? = ok
          def listed? = listed
          def catalogue? = scope == "catalogue"
        end

        class Failure < StandardError
          attr_reader :kind

          def initialize(kind, message)
            @kind = kind
            super(message)
          end
        end

        def initialize(config)
          @config = config
        end

        def call
          precheck!
          @scope = provider.models_scope
          models = list
          Result.new(ok: true, models: models.first(MAX_MODELS), listed: true,
                     message: success_message(models), scope: @scope)
        rescue Failure => e
          Result.new(ok: false, models: [], error_kind: e.kind, message: filter(e.message), listed: false,
                     scope: provider.models_scope)
        end

        def verify_model # rubocop:disable Metrics/AbcSize
          precheck!
          raise Failure.new(:incomplete, t("errors.model_missing")) if config.model.blank?

          Client.new(config:).chat(messages: [{ role: "user", content: VERIFY_PROMPT }], max_tokens: VERIFY_MAX_TOKENS)
          Result.new(ok: true, models: [], listed: false, scope: provider.models_scope,
                     message: t("verify.ok", model: config.model))
        rescue Failure => e
          Result.new(ok: false, models: [], error_kind: e.kind, message: filter(e.message), listed: false,
                     scope: provider.models_scope)
        rescue Client::Error => e
          verify_failed(e.message)
        rescue StandardError => e # raised by the HTTP stack instead of an error response
          verify_failed(e.class.name.to_s.demodulize)
        end

        def verify_failed(detail)
          Result.new(ok: false, models: [], error_kind: :model, listed: false, scope: provider.models_scope,
                     message: filter(t("verify.failed", model: config.model, detail:)))
        end

        private

        attr_reader :config

        delegate :provider, to: :config

        def precheck!
          unless ProviderConfig.valid_url?(config.base_url)
            raise Failure.new(:incomplete, t("errors.base_url_missing"))
          end
          raise Failure.new(:auth, t("errors.key_missing")) if config.key_required? && config.api_key.blank?
        end

        def list
          models = if provider.models == "anthropic"
                     ids(get(config.models_url("limit=1000")))
                   else
                     ids(get(config.models_url)).grep_v(NON_CHAT)
                   end
          models.uniq.sort_by { [it.downcase, it] }
        end

        def ids(json)
          Array(json.is_a?(Hash) ? json["data"] : json).filter_map do |item|
            id = item.is_a?(Hash) ? item["id"] : item
            id.to_s.strip.presence if id.is_a?(String)
          end
        end

        def get(url) # rubocop:disable Metrics/AbcSize
          response = begin
            http.get(url, headers: config.headers.except("Content-Type"))
          rescue StandardError => e # raised instead of wrapped in an ErrorResponse
            error!(e)
          end
          error!(response.error) if CiConnections::Http.error_response?(response)
          length = Array(response.headers["content-length"]).first.to_i
          raise Failure.new(:unexpected, t("errors.too_large")) if length > MAX_BYTES

          text = response.body.to_s
          raise Failure.new(:unexpected, t("errors.too_large")) if text.bytesize > MAX_BYTES

          status!(response.status.to_i, text)
          JSON.parse(text)
        rescue JSON::ParserError
          raise Failure.new(:unexpected, t("errors.unexpected"))
        end

        def http
          OpenProject.httpx.with(timeout: { request_timeout: TIMEOUT, read_timeout: TIMEOUT,
                                            connect_timeout: CONNECT_TIMEOUT })
        end

        def status!(status, text)
          return if status.between?(200, 299)

          detail = provider_detail(text)
          kind, key = case status
                      when 401, 403 then %i[auth auth]
                      when 404 then %i[not_found not_found]
                      when 429 then %i[rate_limited rate_limited]
                      else %i[http http]
                      end
          raise Failure.new(kind, [t("errors.#{key}", status:, host: config.host), detail].compact.join(" – "))
        end

        def provider_detail(text)
          parsed = JSON.parse(text)
          error = parsed.is_a?(Hash) ? (parsed["error"] || parsed["message"] || parsed["detail"]) : nil
          error = error["message"] if error.is_a?(Hash)
          error.is_a?(String) ? error.first(300) : nil
        rescue JSON::ParserError
          nil
        end

        def error!(error) # rubocop:disable Metrics/AbcSize
          if CiConnections::Http.ssrf?(error)
            addresses = CiConnections::Http.resolve(config.host.to_s)
            raise Failure.new(:ssrf, t("errors.ssrf", host: config.host, env: CiConnections::Http::SSRF_ENV,
                                                      addresses: addresses.any? ? addresses.join(", ") : "?"))
          end
          raise Failure.new(:timeout, t("errors.timeout", host: config.host, seconds: TIMEOUT)) if timeout?(error)
          raise Failure.new(:tls, t("errors.tls", host: config.host, detail: error.message.to_s.first(200))) if CiConnections::Http.tls?(error)

          raise Failure.new(:network, t("errors.network", host: config.host, detail: error.class.name.to_s.demodulize))
        end

        def timeout?(error)
          error.is_a?(::Timeout::Error) || (defined?(::HTTPX::TimeoutError) && error.is_a?(::HTTPX::TimeoutError))
        end

        def success_message(models)
          models.empty? ? t("success_no_models") : t("success", count: models.size)
        end

        def filter(message)
          key = config.api_key
          message = message.to_s
          key.present? ? message.gsub(key, "[FILTERED]") : message
        end

        def t(key, **)
          I18n.t("test_management.admin.assistant.test.#{key}", **)
        end
      end
    end
  end
end
