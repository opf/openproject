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
    class Client
      MAX_RESPONSE_BYTES = 1_000_000

      class Error < StandardError; end
      class NotConfigured < Error; end

      Response = Struct.new(:content, :finish_reason, keyword_init: true)

      attr_reader :config

      def initialize(config:)
        @config = config
      end

      def chat(messages:, max_tokens: nil) # rubocop:disable Metrics/AbcSize
        raise NotConfigured, I18n.t("test_management.assistant.errors.not_configured") unless config.configured?

        limit = (max_tokens.presence || config.max_tokens).to_i.clamp(1, ProviderConfig::MAX_TOKENS_RANGE.max)
        body = { model: config.model, messages:, config.provider.token_param => limit }
        parse(request(body))
      end

      private

      def request(body) # rubocop:disable Metrics/AbcSize
        response = http.post(config.chat_url, headers: config.headers, json: body)
        if CiConnections::Http.error_response?(response)
          fail!(response.error.class.name.demodulize)
        end
        text = response.body.to_s
        fail!(I18n.t("test_management.assistant.errors.response_too_large")) if text.bytesize > MAX_RESPONSE_BYTES
        status = response.status.to_i
        fail!(http_error(status, text)) unless status.between?(200, 299)

        text
      end

      def http
        OpenProject.httpx.with(timeout: { request_timeout: config.timeout, read_timeout: config.timeout })
      end

      def parse(text)
        json = JSON.parse(text)
        message = json.dig("choices", 0, "message")
        fail!(I18n.t("test_management.assistant.errors.unexpected_response")) unless message.is_a?(Hash)

        content = message["content"].presence
        fail!(I18n.t("test_management.assistant.errors.empty_reply")) if content.blank?

        Response.new(content:, finish_reason: json.dig("choices", 0, "finish_reason"))
      rescue JSON::ParserError
        fail!(I18n.t("test_management.assistant.errors.unexpected_response"))
      end

      def http_error(status, text)
        detail = begin
          parsed = JSON.parse(text)
          error = parsed.is_a?(Hash) ? parsed["error"] : nil
          error.is_a?(Hash) ? error["message"] : error
        rescue JSON::ParserError
          nil
        end
        ["HTTP #{status}", detail.is_a?(String) ? detail.first(300) : nil].compact.join(": ")
      end

      def fail!(message)
        text = "#{config.label}: #{message}"
        key = config.api_key
        text = text.gsub(key, "[FILTERED]") if key.present?
        raise Error, text.first(600)
      end
    end
  end
end
