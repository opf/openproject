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
    class ProviderConfig
      KEY_SALT = "openproject test_management assistant api key"
      DEFAULT_TIMEOUT = 90
      TIMEOUT_RANGE = (10..300)
      DEFAULT_MAX_TOKENS = 4096
      MAX_TOKENS_RANGE = (256..32_000)

      def self.apply(settings, params) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        params = params.to_h.stringify_keys
        merged = settings.to_h.stringify_keys.dup
        errors = []

        provider_key = params["assistant_provider"].presence || AI::Provider::DEFAULT_KEY
        errors << I18n.t("test_management.admin.assistant.errors.provider") unless AI::Provider.valid?(provider_key)
        provider = AI::Provider.find(provider_key)
        base_url = normalize_base_url(params["assistant_base_url"].to_s.strip, provider)
        base_url = "" if base_url != provider.base_url && AI::Provider.default_base_url?(base_url)
        errors << I18n.t("test_management.admin.assistant.errors.base_url") if base_url.present? && !valid_url?(base_url)
        model = params["assistant_model"].to_s.strip
        errors << I18n.t("test_management.admin.assistant.errors.model") if model.length > 255
        timeout = integer_in(params["assistant_timeout"], TIMEOUT_RANGE, DEFAULT_TIMEOUT)
        if timeout.nil?
          errors << I18n.t("test_management.admin.assistant.errors.timeout", min: TIMEOUT_RANGE.min, max: TIMEOUT_RANGE.max)
        end
        max_tokens = integer_in(params["assistant_max_tokens"], MAX_TOKENS_RANGE, DEFAULT_MAX_TOKENS)
        if max_tokens.nil?
          errors << I18n.t("test_management.admin.assistant.errors.max_tokens",
                           min: MAX_TOKENS_RANGE.min, max: MAX_TOKENS_RANGE.max)
        end
        return [settings, errors] if errors.any?

        merged["assistant_provider"] = provider.key
        merged["assistant_base_url"] = base_url
        merged["assistant_model"] = model
        merged["assistant_auth_style"] = provider.auth_style
        merged["assistant_timeout"] = timeout
        merged["assistant_max_tokens"] = max_tokens
        if ActiveModel::Type::Boolean.new.cast(params["remove_api_key"])
          merged["assistant_api_key_ciphertext"] = nil
        elsif params["assistant_api_key"].to_s.strip.present?
          merged["assistant_api_key_ciphertext"] = CiTokenCipher.encrypt(params["assistant_api_key"].to_s.strip, salt: KEY_SALT)
        elsif stored_key_for_other_endpoint?(settings, merged)
          return [settings, [I18n.t("test_management.admin.assistant.errors.api_key_reenter", provider: provider.label)]] if new(merged).key_required?

          merged["assistant_api_key_ciphertext"] = nil
        end
        [merged, []]
      end

      def self.stored_key_for_other_endpoint?(stored_settings, new_settings)
        stored = new(stored_settings)
        stored.api_key_set? && stored.endpoint != new(new_settings).endpoint
      end

      def self.normalize_base_url(value, _provider)
        uri = URI.parse(value)
        return value unless uri.is_a?(URI::HTTP) && uri.path.to_s.delete("/").empty?

        uri.path = "/v1"
        uri.to_s
      rescue URI::InvalidURIError
        value
      end

      def self.valid_url?(value)
        uri = URI.parse(value.to_s)
        uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil?
      rescue URI::InvalidURIError
        false
      end

      def self.integer_in(value, range, default)
        return default if value.blank?
        return nil unless value.to_s.strip.match?(/\A\d+\z/)

        int = value.to_i
        range.cover?(int) ? int : nil
      end

      attr_reader :name, :provider_id

      def initialize(settings = nil, name: nil, provider_id: nil, **unbraced)
        @settings = settings.to_h.merge(unbraced).stringify_keys
        @name = name
        @provider_id = provider_id
      end

      def provider = AI::Provider.find(@settings["assistant_provider"])
      def base_url = @settings["assistant_base_url"].to_s.strip.presence || provider.base_url.to_s
      def model = @settings["assistant_model"].to_s.strip
      def auth_style = provider.auth_style.presence || "bearer"
      def key_required? = provider.key_required
      def timeout = self.class.integer_in(@settings["assistant_timeout"], TIMEOUT_RANGE, DEFAULT_TIMEOUT) || DEFAULT_TIMEOUT
      def max_tokens = self.class.integer_in(@settings["assistant_max_tokens"], MAX_TOKENS_RANGE, DEFAULT_MAX_TOKENS) || DEFAULT_MAX_TOKENS
      def api_key_set? = @settings["assistant_api_key_ciphertext"].present?

      def api_key
        return @api_key if defined?(@api_key)

        @api_key = CiTokenCipher.decrypt(@settings["assistant_api_key_ciphertext"], salt: KEY_SALT)
      end

      def api_key_unreadable? = api_key_set? && api_key.nil?
      def configured? = self.class.valid_url?(base_url) && model.present? && (!key_required? || api_key.present?)

      def host
        URI.parse(base_url).host
      rescue URI::InvalidURIError
        nil
      end

      def endpoint = [provider.key, host.to_s.downcase]
      def label = "#{host || '?'} / #{model.presence || '?'}"
      def completions_url = endpoint_url("/chat/completions")
      def chat_url = completions_url

      def models_url(query = nil)
        uri = URI.parse(base_url)
        path = uri.path.to_s.chomp("/").delete_suffix("/chat/completions")
        uri.path = "#{path}/models"
        uri.query = [uri.query.presence, query.presence].compact.join("&").presence
        uri.to_s
      end

      def sibling_url(path, root: false)
        uri = URI.parse(base_url)
        base_path = root ? "" : uri.path.to_s.chomp("/").delete_suffix("/chat/completions")
        uri.path = "#{base_path}#{path}"
        uri.query = nil if root
        uri.to_s
      end

      def headers
        headers = { "Content-Type" => "application/json", "Accept" => "application/json" }
        headers.merge!(provider.headers)
        headers["Authorization"] = "Bearer #{api_key}" if api_key.present? && auth_style == "bearer"
        headers
      end

      private

      def endpoint_url(suffix)
        uri = URI.parse(base_url)
        path = uri.path.to_s.chomp("/")
        uri.path = path.end_with?(suffix) ? path : "#{path}#{suffix}"
        uri.to_s
      end
    end
  end
end
