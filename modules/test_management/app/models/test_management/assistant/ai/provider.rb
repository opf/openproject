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
      class Provider
        Preset = Struct.new(:key, :api, :base_url, :auth_style, :key_required, :headers, :models,
                            :token_param, :tool_choice, :model_placeholder, :base_url_placeholder,
                            :model_free_text, :docs_url, :models_scope, keyword_init: true) do
          def custom? = key == "custom"
          def anthropic? = api == "anthropic"
          def label = I18n.t("test_management.admin.assistant.providers.#{key}")
          def key_scoped_models? = models_scope == "key"
        end

        ANTHROPIC_VERSION = "2023-06-01"

        # shortcut: openai/anthropic/custom only, other presets in a later AI PR
        DOCS_URLS = {
          "openai" => "https://platform.openai.com/docs/api-reference/chat",
          "anthropic" => "https://docs.claude.com/en/api/messages"
        }.freeze

        PRESETS = [
          Preset.new(key: "openai", api: "openai", base_url: "https://api.openai.com/v1", auth_style: "bearer",
                     key_required: true, headers: {}, models: "openai", token_param: :max_completion_tokens,
                     tool_choice: true, model_placeholder: "gpt-4o-mini",
                     docs_url: DOCS_URLS.fetch("openai"), models_scope: "catalogue"),
          Preset.new(key: "anthropic", api: "anthropic", base_url: "https://api.anthropic.com/v1", auth_style: "x_api_key",
                     key_required: true, headers: { "anthropic-version" => ANTHROPIC_VERSION }, models: "anthropic",
                     token_param: :max_tokens, tool_choice: true, model_placeholder: "claude-sonnet-4-5",
                     docs_url: DOCS_URLS.fetch("anthropic"), models_scope: "catalogue"),
          Preset.new(key: "custom", api: "openai", base_url: "", auth_style: nil,
                     key_required: nil, headers: {}, models: "generic", token_param: :max_tokens, tool_choice: true,
                     model_placeholder: "gpt-4o-mini", base_url_placeholder: "https://llm.example.com/v1",
                     docs_url: nil, models_scope: "catalogue")
        ].freeze

        KEYS = PRESETS.map(&:key).freeze
        DEFAULT_KEY = "custom"

        def self.all = PRESETS

        def self.find(key)
          PRESETS.find { it.key == key.to_s } || PRESETS.find(&:custom?)
        end

        def self.docs_url_for(key) = DOCS_URLS[key.to_s]

        def self.valid?(key) = KEYS.include?(key.to_s)

        def self.default_base_url?(url)
          url.to_s.strip.present? && PRESETS.any? { it.base_url == url.to_s.strip.chomp("/") }
        end
      end
    end
  end
end
