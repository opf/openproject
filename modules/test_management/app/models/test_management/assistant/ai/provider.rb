# frozen_string_literal: true

module TestManagement
  module Assistant
    module AI
      # Provider presets for the Test Assistant (Administration > Test management). A preset fills
      # in the base URL, the authentication and any fixed headers; the base URL always stays
      # editable (proxies, gateways, in-cluster Ollama). "custom" is any OpenAI-compatible server and
      # the default for settings stored before presets existed.
      #
      #   api          "openai"    POST {base}/chat/completions, OpenAI request/response shape
      #                "anthropic" POST {base}/messages, native Anthropic Messages API (AnthropicAdapter)
      #   auth_style   bearer | api_key | x_api_key | none (custom: chosen in the form)
      #   key_required false: a key is optional and only sent when present (Ollama local vs. cloud)
      #   models       how "Test connection" lists and filters chat models (AI::ConnectionTest)
      #   models_scope key       the list holds only what the entered key/account can use (0021)
      #                catalogue the provider lists its whole catalogue; the form says so and checks the
      #                          model with a tiny request on save
      #                none      no list (Azure: deployments are not listable with the resource key)
      #
      # Sources for every value: docs/assistant/ai-providers.md.
      class Provider
        Preset = Struct.new(:key, :api, :base_url, :auth_style, :key_required, :headers, :models,
                            :token_param, :tool_choice, :model_placeholder, :base_url_placeholder,
                            :model_free_text, :docs_url, :models_scope, keyword_init: true) do
          def custom? = key == "custom"
          def anthropic? = api == "anthropic"
          def label = I18n.t("test_management.admin.assistant.providers.#{key}")
          # "Test connection" lists only what the key can use (0021); otherwise a model is checked on save.
          def key_scoped_models? = models_scope == "key"
        end

        ANTHROPIC_VERSION = "2023-06-01"

        # Literal map so views can link without reading a Struct attribute (Brakeman LinkToHref).
        DOCS_URLS = {
          "openai" => "https://platform.openai.com/docs/api-reference/chat",
          "anthropic" => "https://docs.claude.com/en/api/messages",
          "openrouter" => "https://openrouter.ai/docs/api-reference/overview",
          "ollama" => "https://docs.ollama.com/api/openai-compatibility",
          "xai" => "https://docs.x.ai/docs/api-reference",
          "mistral" => "https://docs.mistral.ai/api/",
          "azure" => "https://learn.microsoft.com/azure/ai-foundry/openai/reference"
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
          Preset.new(key: "openrouter", api: "openai", base_url: "https://openrouter.ai/api/v1", auth_style: "bearer",
                     key_required: true, headers: { "X-Title" => "OpenProject Test Management" }, models: "openrouter",
                     token_param: :max_tokens, tool_choice: true, model_placeholder: "openai/gpt-4o-mini",
                     docs_url: DOCS_URLS.fetch("openrouter"), models_scope: "key"),
          Preset.new(key: "ollama", api: "openai", base_url: "http://localhost:11434/v1", auth_style: "bearer",
                     key_required: false, headers: {}, models: "ollama", token_param: :max_tokens, tool_choice: false,
                     model_placeholder: "llama3.1:8b", base_url_placeholder: "http://ollama.<namespace>.svc:11434/v1",
                     docs_url: DOCS_URLS.fetch("ollama"), models_scope: "key"),
          Preset.new(key: "xai", api: "openai", base_url: "https://api.x.ai/v1", auth_style: "bearer",
                     key_required: true, headers: {}, models: "xai", token_param: :max_tokens, tool_choice: true,
                     model_placeholder: "grok-3-mini", docs_url: DOCS_URLS.fetch("xai"), models_scope: "key"),
          Preset.new(key: "mistral", api: "openai", base_url: "https://api.mistral.ai/v1", auth_style: "bearer",
                     key_required: true, headers: {}, models: "mistral", token_param: :max_tokens, tool_choice: true,
                     model_placeholder: "mistral-small-latest", docs_url: DOCS_URLS.fetch("mistral"), models_scope: "key"),
          Preset.new(key: "azure", api: "openai", base_url: "", auth_style: "api_key",
                     key_required: true, headers: {}, models: "azure", token_param: :max_completion_tokens,
                     tool_choice: true, model_placeholder: "my-gpt-4o-deployment", model_free_text: true,
                     base_url_placeholder: "https://<resource>.openai.azure.com/openai/v1",
                     docs_url: DOCS_URLS.fetch("azure"), models_scope: "none"),
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

        # Default base URLs of all presets (used to tell "untouched preset default" from a custom URL).
        def self.default_base_url?(url)
          url.to_s.strip.present? && PRESETS.any? { it.base_url == url.to_s.strip.chomp("/") }
        end
      end
    end
  end
end
