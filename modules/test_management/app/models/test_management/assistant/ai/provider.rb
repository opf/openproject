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
                            :docs_url, :models_scope, keyword_init: true) do
          def label = I18n.t("test_management.admin.assistant.providers.#{key}")
          def key_scoped_models? = models_scope == "key"
        end

        DOCS_URLS = {
          "openrouter" => "https://openrouter.ai/docs/api-reference/overview",
          "mistral" => "https://docs.mistral.ai/api/"
        }.freeze

        PRESETS = [
          Preset.new(key: "openrouter", api: "openai", base_url: "https://openrouter.ai/api/v1", auth_style: "bearer",
                     key_required: true, headers: { "X-Title" => "OpenProject Test Management" }, models: "openrouter",
                     token_param: :max_tokens, tool_choice: true, model_placeholder: "openai/gpt-4o-mini",
                     docs_url: DOCS_URLS.fetch("openrouter"), models_scope: "key"),
          Preset.new(key: "mistral", api: "openai", base_url: "https://api.mistral.ai/v1", auth_style: "bearer",
                     key_required: true, headers: {}, models: "mistral", token_param: :max_tokens, tool_choice: true,
                     model_placeholder: "mistral-small-latest", docs_url: DOCS_URLS.fetch("mistral"), models_scope: "key")
        ].freeze

        KEYS = PRESETS.map(&:key).freeze
        DEFAULT_KEY = "openrouter"

        def self.all = PRESETS

        def self.find(key)
          PRESETS.find { it.key == key.to_s } || PRESETS.first
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
