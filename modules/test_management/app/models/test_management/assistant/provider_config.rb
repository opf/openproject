# frozen_string_literal: true

module TestManagement
  module Assistant
    # The AI provider of the Test Assistant (Administration > Test management > Test Assistant).
    #
    # provider     a preset (AI::Provider: openai, anthropic, openrouter, ollama, xai, mistral, azure)
    #              or "custom" (default, also for settings stored before presets existed). A preset
    #              fixes the API shape and authentication and pre-fills the base URL.
    #
    # Custom: one OpenAI-compatible "chat completions" endpoint covers OpenAI, Azure OpenAI, Ollama,
    # OpenRouter, vLLM, LM Studio, LiteLLM and similar gateways:
    #   base URL     e.g. https://api.openai.com/v1, http://ollama:11434/v1,
    #                https://<res>.openai.azure.com/openai/deployments/<deployment>?api-version=2024-10-21
    #                ("/chat/completions" is appended before any query string)
    #   model        e.g. gpt-4o-mini, llama3.1:8b (Azure: the deployment's model, sent but ignored)
    #   auth style   bearer (Authorization: Bearer <key>) | api_key (Azure "api-key" header) | none
    #   API key      AES-256-GCM encrypted at rest (CiTokenCipher with its own key salt); write-only,
    #                never rendered or returned by the API
    #
    # 0021: the values live in saved providers (TestManagement::AssistantProvider#settings, same keys);
    # .current is the default provider. The plugin setting (Setting.plugin_openproject_test_management
    # assistant_*) is only read while no provider is saved (it is moved into the first provider by the
    # 0021 migration).
    class ProviderConfig
      KEY_SALT = "openproject test_management assistant api key"
      AUTH_STYLES = %w[bearer api_key none].freeze # selectable for "custom"; presets may use x_api_key
      DEFAULT_TIMEOUT = 90
      TIMEOUT_RANGE = (10..300)
      DEFAULT_MAX_TOKENS = 4096
      MAX_TOKENS_RANGE = (256..32_000)
      SETTING_KEYS = %w[assistant_provider assistant_base_url assistant_model assistant_api_key_ciphertext assistant_auth_style
                        assistant_timeout assistant_max_tokens].freeze

      def self.current
        TestManagement::AssistantProvider.default_provider&.config || new(stored_settings)
      end

      def self.stored_settings
        Hash(Setting.plugin_openproject_test_management).stringify_keys
      end

      # Validates the admin form and returns [settings_to_store, errors]. A blank API key keeps
      # the stored one while provider and host stay the same; remove_api_key clears it. After a
      # provider or host change a blank key is an error when the new provider needs a key, and
      # clears the stored key when it does not (Ollama, custom with authentication "None").
      def self.apply(settings, params)
        params = params.to_h.stringify_keys
        merged = settings.to_h.stringify_keys.dup
        errors = []

        provider_key = params["assistant_provider"].presence || AI::Provider::DEFAULT_KEY
        errors << I18n.t("test_management.admin.assistant.errors.provider") unless AI::Provider.valid?(provider_key)
        provider = AI::Provider.find(provider_key)
        base_url = normalize_base_url(params["assistant_base_url"].to_s.strip, provider)
        # Another preset's default URL left in the field (provider switched without the form
        # refresh): use this preset's default instead.
        base_url = "" if !provider.custom? && base_url != provider.base_url && AI::Provider.default_base_url?(base_url)
        if base_url.present? && !valid_url?(base_url)
          errors << I18n.t("test_management.admin.assistant.errors.base_url")
        end
        model = params["assistant_model"].to_s.strip
        errors << I18n.t("test_management.admin.assistant.errors.model") if model.length > 255
        auth_style = params["assistant_auth_style"].presence || "bearer"
        errors << I18n.t("test_management.admin.assistant.errors.auth_style") unless AUTH_STYLES.include?(auth_style)
        timeout = integer_in(params["assistant_timeout"], TIMEOUT_RANGE, DEFAULT_TIMEOUT)
        if timeout.nil?
          errors << I18n.t("test_management.admin.assistant.errors.timeout", min: TIMEOUT_RANGE.min,
                                                                             max: TIMEOUT_RANGE.max)
        end
        max_tokens = integer_in(params["assistant_max_tokens"], MAX_TOKENS_RANGE, DEFAULT_MAX_TOKENS)
        if max_tokens.nil?
          errors << I18n.t("test_management.admin.assistant.errors.max_tokens", min: MAX_TOKENS_RANGE.min,
                                                                                max: MAX_TOKENS_RANGE.max)
        end
        return [settings, errors] if errors.any?

        merged["assistant_provider"] = provider.key
        merged["assistant_base_url"] = base_url
        merged["assistant_model"] = model
        merged["assistant_auth_style"] = auth_style
        merged["assistant_timeout"] = timeout
        merged["assistant_max_tokens"] = max_tokens
        if ActiveModel::Type::Boolean.new.cast(params["remove_api_key"])
          merged["assistant_api_key_ciphertext"] = nil
        elsif params["assistant_api_key"].to_s.strip.present?
          merged["assistant_api_key_ciphertext"] = CiTokenCipher.encrypt(params["assistant_api_key"].to_s.strip, salt: KEY_SALT)
        elsif stored_key_for_other_endpoint?(settings, merged)
          # 0019b: a blank key field never carries the stored key over to another provider or host.
          if new(merged).key_required?
            return [settings,
                    [I18n.t("test_management.admin.assistant.errors.api_key_reenter",
                            provider: provider.label)]]
          end

          merged["assistant_api_key_ciphertext"] = nil # the new provider needs none (e.g. a local Ollama)
        end
        [merged, []]
      end

      # The stored key belongs to the stored provider and host. It is reused only while both stay the same.
      def self.stored_key_for_other_endpoint?(stored_settings, new_settings)
        stored = new(stored_settings)
        return false unless stored.api_key_set?

        stored.endpoint != new(new_settings).endpoint
      end

      # Ollama is often entered as http://host:11434 – its OpenAI-compatible API lives under /v1.
      def self.normalize_base_url(value, provider)
        return value unless provider.key == "ollama" && value.present?

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

      # nil = invalid, blank = default
      def self.integer_in(value, range, default)
        return default if value.blank?
        return nil unless value.to_s.strip.match?(/\A\d+\z/)

        int = value.to_i
        range.cover?(int) ? int : nil
      end

      attr_reader :name, :provider_id

      # name, provider_id: the saved provider (0021), nil for the former plugin setting.
      # 0021b: settings given without braces (new("assistant_model" => "x")) arrive as keywords in
      # Ruby 3 because of the name:/provider_id: keywords; they are taken as settings again.
      def initialize(settings = nil, name: nil, provider_id: nil, **unbraced)
        @settings = settings.to_h.merge(unbraced).stringify_keys
        @name = name
        @provider_id = provider_id
      end

      def provider
        AI::Provider.find(@settings["assistant_provider"])
      end

      delegate :anthropic?, to: :provider

      # The stored URL, or the preset's default when the field was left empty.
      def base_url
        @settings["assistant_base_url"].to_s.strip.presence || provider.base_url.to_s
      end

      def model
        @settings["assistant_model"].to_s.strip
      end

      def auth_style
        return provider.auth_style unless provider.custom?

        AUTH_STYLES.include?(@settings["assistant_auth_style"]) ? @settings["assistant_auth_style"] : "bearer"
      end

      def key_required?
        provider.custom? ? auth_style != "none" : provider.key_required
      end

      def timeout
        self.class.integer_in(@settings["assistant_timeout"], TIMEOUT_RANGE, DEFAULT_TIMEOUT) || DEFAULT_TIMEOUT
      end

      def max_tokens
        self.class.integer_in(@settings["assistant_max_tokens"], MAX_TOKENS_RANGE, DEFAULT_MAX_TOKENS) || DEFAULT_MAX_TOKENS
      end

      def api_key_set?
        @settings["assistant_api_key_ciphertext"].present?
      end

      def api_key
        return @api_key if defined?(@api_key)

        @api_key = CiTokenCipher.decrypt(@settings["assistant_api_key_ciphertext"], salt: KEY_SALT)
      end

      def api_key_unreadable?
        api_key_set? && api_key.nil?
      end

      def configured?
        self.class.valid_url?(base_url) && model.present? && (!key_required? || api_key.present?)
      end

      def host
        URI.parse(base_url).host
      rescue URI::InvalidURIError
        nil
      end

      # Provider and host the stored API key was entered for.
      def endpoint
        [provider.key, host.to_s.downcase]
      end

      # Shown in errors and stored on generations/messages (never includes the key).
      def label
        "#{host || '?'} / #{model.presence || '?'}"
      end

      # Picker and records (0021): "OpenAI · gpt-4o-mini"; the host label without a saved provider.
      def display_label
        name.present? ? "#{name} · #{model.presence || '?'}" : label
      end

      def completions_url
        endpoint_url("/chat/completions")
      end

      def messages_url
        endpoint_url("/messages")
      end

      # Where chat requests go: Anthropic's native Messages API or OpenAI chat completions.
      def chat_url
        anthropic? ? messages_url : completions_url
      end

      # {base}/models – a configured ".../chat/completions" base is cut back first.
      def models_url(query = nil)
        uri = URI.parse(base_url)
        path = uri.path.to_s.chomp("/").delete_suffix("/chat/completions").delete_suffix("/messages")
        uri.path = "#{path}/models"
        uri.query = [uri.query.presence, query.presence].compact.join("&").presence
        uri.to_s
      end

      # Another path next to /models (e.g. OpenRouter's /key, Ollama's native /api/tags).
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
        return headers if api_key.blank?

        case auth_style
        when "bearer" then headers["Authorization"] = "Bearer #{api_key}"
        when "api_key" then headers["api-key"] = api_key.to_s
        when "x_api_key" then headers["x-api-key"] = api_key.to_s
        end
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
