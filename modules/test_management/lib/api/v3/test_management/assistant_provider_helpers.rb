# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Saved AI providers of the Test Assistant (0021).
      #   Administrators: full provider (never the key: apiKeySet only), create/update/delete/default.
      #   Users with "Use test assistant" in any project: id, name, models and which one they picked –
      #   no base URL, authentication or key.
      module AssistantProviderHelpers
        WRITE_FIELDS = {
          "preset" => "assistant_provider", "baseUrl" => "assistant_base_url", "model" => "assistant_model",
          "authStyle" => "assistant_auth_style", "apiKey" => "assistant_api_key", "removeApiKey" => "remove_api_key",
          "timeout" => "assistant_timeout", "maxTokens" => "assistant_max_tokens", "name" => "name",
          "userModels" => "user_models", "default" => "make_default", "verifyModel" => "verify_model"
        }.freeze

        def provider_reader!
          return if current_user.admin?
          return if current_user.allowed_in_any_project?(:use_test_assistant)

          raise ::API::Errors::Unauthorized
        end

        def provider_admin!
          raise ::API::Errors::Unauthorized unless current_user.admin?
        end

        def find_assistant_provider!(id)
          ::TestManagement::AssistantProvider.find_by(id:) || raise(::API::Errors::NotFound.new)
        end

        # camelCase body -> provider form. PATCH keeps the stored values of omitted fields.
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

        def assistant_provider_json(provider, choice = nil)
          return admin_provider_json(provider) if current_user.admin?

          {
            _type: "TestManagementAssistantProvider",
            id: provider.id,
            name: provider.name,
            model: provider.model,
            models: provider.selectable_models,
            default: provider.is_default,
            selected: choice&.provider&.id == provider.id,
            selectedModel: choice&.provider&.id == provider.id ? choice.model : nil,
            _links: { self: { href: api_v3_paths.test_management_assistant_provider(provider.id) } }
          }
        end

        def admin_provider_json(provider)
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
