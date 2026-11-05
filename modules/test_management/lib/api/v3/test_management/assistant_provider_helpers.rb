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

module API
  module V3
    module TestManagement
      module AssistantProviderHelpers
        WRITE_FIELDS = {
          "preset" => "assistant_provider", "baseUrl" => "assistant_base_url", "model" => "assistant_model",
          "authStyle" => "assistant_auth_style", "apiKey" => "assistant_api_key", "removeApiKey" => "remove_api_key",
          "timeout" => "assistant_timeout", "maxTokens" => "assistant_max_tokens", "name" => "name",
          "userModels" => "user_models", "default" => "make_default", "verifyModel" => "verify_model"
        }.freeze

        def provider_admin!
          raise ::API::Errors::Unauthorized unless current_user.admin?
        end

        def find_assistant_provider!(id)
          ::TestManagement::AssistantProvider.find_by(id:) || raise(::API::Errors::NotFound.new)
        end

        def provider_form(body, provider)
          form = provider.new_record? ? {} : provider.settings.except("assistant_api_key_ciphertext").transform_values(&:to_s)
          body.each do |key, value|
            target = WRITE_FIELDS[key]
            next unless target

            form[target] = value.is_a?(Array) ? value.map(&:to_s) : value.to_s
          end
          form
        end

        def save_assistant_provider!(provider, body)
          result = ::TestManagement::Assistant::ProviderSaveService.new(provider).call(provider_form(body, provider))
          raise ::API::Errors::UnprocessableContent.new(result.errors.join(" ")) unless result.success?

          result.provider.reload
        end

        def assistant_provider_json(provider) # rubocop:disable Metrics/AbcSize
          config = provider.config
          {
            _type: "TestManagementAssistantProvider",
            id: provider.id,
            name: provider.name,
            preset: provider.preset_definition.key,
            baseUrl: config.base_url,
            authStyle: config.auth_style,
            model: provider.model,
            userModels: Array(provider.user_models),
            models: provider.selectable_models,
            timeout: config.timeout,
            maxTokens: config.max_tokens,
            default: provider.is_default,
            apiKeySet: config.api_key_set?,
            configured: config.configured?,
            modelsScope: provider.preset_definition.models_scope,
            createdAt: provider.created_at&.utc&.iso8601,
            updatedAt: provider.updated_at&.utc&.iso8601,
            _links: {
              self: { href: api_v3_paths.test_management_assistant_provider(provider.id) },
              makeDefault: { href: api_v3_paths.test_management_assistant_provider_default(provider.id), method: :post }
            }
          }
        end
      end
    end
  end
end
