# frozen_string_literal: true

module TestManagement
  module Assistant
    module AI
      # "Test connection" in the provider form: checks base URL + key with the provider's models
      # endpoint and returns the chat-capable models (sorted, de-duplicated) for the Model select.
      #
      # * Runs with the values entered in the form (an unsaved ProviderConfig); a blank key field
      #   means the stored key.
      # * OpenProject.httpx (SSRF filter, no redirects), TIMEOUT seconds, body capped at MAX_BYTES.
      # * Errors are classified (auth, network, ssrf, timeout, tls, not_found, rate_limited, http,
      #   unexpected) and never contain the API key.
      # * 0021: the most key-specific list each provider documents (OpenRouter /models/user, xAI
      #   /language-models, Mistral and Ollama as they are). Result#scope says whether the list is
      #   limited to the key ("key"), the provider's catalogue ("catalogue") or not a list ("none"),
      #   see docs/assistant/ai-providers.md. #verify_model sends one tiny chat request to check that
      #   the chosen model answers with this key (used by "Check the model when saving").
      class ConnectionTest
        TIMEOUT = 10
        CONNECT_TIMEOUT = 5
        MAX_BYTES = 5_000_000
        MAX_MODELS = 1000
        VERIFY_MAX_TOKENS = 16
        VERIFY_PROMPT = "Reply with OK."

        # Names of OpenAI-style models that cannot chat (embeddings, audio, images, moderation, …).
        NON_CHAT = /embed|whisper|tts|dall-e|davinci|babbage|moderation|audio|realtime|transcribe|
                    image|imagine|video|search|sora|computer-use|rerank|ocr/x

        Result = Struct.new(:ok, :models, :error_kind, :message, :listed, :scope, keyword_init: true) do
          def ok? = ok
          # Models were listed (Azure only verifies the key: its list is not the deployments).
          def listed? = listed
          # The list may hold models the key cannot use (0021).
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
          Result.new(ok: true, models: models.first(MAX_MODELS), listed: provider.models != "azure",
                     message: success_message(models), scope: @scope)
        rescue Failure => e
          Result.new(ok: false, models: [], error_kind: e.kind, message: filter(e.message), listed: false,
                     scope: provider.models_scope)
        end

        # One tiny chat request to the configured model (0021). ok: the provider answered.
        def verify_model
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
          case provider.models
          when "anthropic" then ids(get(config.models_url("limit=1000")))
          when "openrouter" then openrouter_for_key
          when "xai" then xai
          when "mistral" then mistral(get(config.models_url))
          when "ollama" then ollama
          else ids(get(config.models_url)).grep_v(NON_CHAT)
          end.uniq.sort_by { [it.downcase, it] }
        end

        # GET /models/user: the models the key may use (provider preferences, privacy settings and
        # guardrails), text output only; needs the key. Gateways without it: key check + full list.
        def openrouter_for_key
          openrouter(get(config.sibling_url("/models/user")))
        rescue Failure => e
          raise unless e.kind == :not_found

          @scope = "catalogue"
          get(config.sibling_url("/key")) # the full /models list is public: check the key first
          openrouter(get(config.models_url))
        end

        # GET /language-models: chat models available to the key (with modalities); /models otherwise.
        def xai
          json = get(config.sibling_url("/language-models"))
          Array(json.is_a?(Hash) ? json["models"] : nil).filter_map do |item|
            next unless item.is_a?(Hash) && item["id"].is_a?(String)

            outputs = Array(item["output_modalities"])
            item["id"] if outputs.empty? || outputs.include?("text")
          end
        rescue Failure => e
          raise unless e.kind == :not_found

          ids(get(config.models_url)).grep_v(NON_CHAT)
        end

        def ids(json)
          Array(json.is_a?(Hash) ? json["data"] : json).filter_map do |item|
            id = item.is_a?(Hash) ? item["id"] : item
            id.to_s.strip.presence if id.is_a?(String)
          end
        end

        def openrouter(json)
          Array(json["data"]).filter_map do |item|
            next unless item.is_a?(Hash) && item["id"].is_a?(String)

            architecture = item["architecture"].is_a?(Hash) ? item["architecture"] : {}
            outputs = Array(architecture["output_modalities"])
            text = outputs.any? ? outputs.include?("text") : architecture["modality"].to_s.match?(/->.*text|\A\z/)
            item["id"] if text
          end
        end

        def mistral(json)
          Array(json["data"]).filter_map do |item|
            next unless item.is_a?(Hash) && item["id"].is_a?(String) && !item["archived"]

            capabilities = item["capabilities"]
            chat = capabilities.is_a?(Hash) ? capabilities["completion_chat"] : !item["id"].match?(NON_CHAT)
            item["id"] if chat
          end
        end

        # /v1/models, then the native /api/tags of older Ollama builds.
        def ollama
          ids(get(config.models_url)).grep_v(/embed/)
        rescue Failure => e
          raise unless e.kind == :not_found

          json = get(config.sibling_url("/api/tags", root: true))
          Array(json["models"]).filter_map { it["name"] if it.is_a?(Hash) && it["name"].is_a?(String) }.grep_v(/embed/)
        end

        def get(url)
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

        def error!(error)
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
          if provider.models == "azure"
            t("success_azure")
          elsif models.empty?
            t("success_no_models")
          else
            t("success", count: models.size)
          end
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
