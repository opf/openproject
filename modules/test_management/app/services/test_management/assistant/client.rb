# frozen_string_literal: true

module TestManagement
  module Assistant
    # Minimal chat client: OpenAI-compatible chat completions (POST {base}/chat/completions) for
    # every preset except Anthropic, which uses its native Messages API (POST {base}/messages,
    # translated by AnthropicAdapter). Per-preset tweaks come from AI::Provider (token parameter,
    # no tool_choice for Ollama, no temperature for Anthropic).
    #
    # * Requests go through OpenProject.httpx (SSRF filter: private and loopback addresses are
    #   refused unless allowed with OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST, e.g. a local Ollama).
    # * Timeout from the provider settings (10–300 s), response body capped at MAX_RESPONSE_BYTES.
    # * Errors name the provider host and model and never contain the API key. There is no
    #   silent fallback to a fake provider: a failing provider is reported as such.
    class Client
      MAX_RESPONSE_BYTES = 1_000_000

      class Error < StandardError; end
      class NotConfigured < Error; end

      ToolCall = Struct.new(:id, :name, :arguments, keyword_init: true)
      Response = Struct.new(:content, :tool_calls, :finish_reason, :usage, keyword_init: true)

      # Normalizes OpenAI-style and Anthropic usage into one hash:
      #   prompt_tokens, completion_tokens, total_tokens, optional reasoning_tokens.
      def self.normalize_usage(raw)
        return nil unless raw.is_a?(Hash)

        prompt = token_count(raw["prompt_tokens"] || raw["input_tokens"])
        completion = token_count(raw["completion_tokens"] || raw["output_tokens"])
        total = token_count(raw["total_tokens"])
        total ||= prompt.to_i + completion.to_i if prompt || completion
        reasoning = token_count(raw.dig("completion_tokens_details", "reasoning_tokens") ||
                                raw["reasoning_tokens"])

        {
          "prompt_tokens" => prompt,
          "completion_tokens" => completion,
          "total_tokens" => total,
          "reasoning_tokens" => reasoning
        }.compact.presence
      end

      def self.token_count(value)
        value&.to_i
      end
      private_class_method :token_count

      attr_reader :config

      def initialize(config: ProviderConfig.current)
        @config = config
      end

      # messages: [{ role:, content: }, ...] (OpenAI format, tool messages included)
      # tools:    OpenAI "function" tool schemas or nil
      # reasoning: optional OpenRouter-style hash, e.g. { effort: "low" } for reasoning models
      def chat(messages:, tools: nil, max_tokens: nil, reasoning: nil)
        raise NotConfigured, I18n.t("test_management.assistant.errors.not_configured") unless config.configured?

        limit = requested_token_limit(max_tokens)
        if config.anthropic?
          body = AnthropicAdapter.body(model: config.model, messages:, tools:, max_tokens: limit)
          return parse_anthropic(request(body))
        end

        body = { model: config.model, messages:, temperature: 0.2, config.provider.token_param => limit }
        body[:reasoning] = reasoning if reasoning.present?
        if tools.present?
          body[:tools] = tools
          body[:tool_choice] = "auto" if config.provider.tool_choice
        end
        parse(request_with_compat_retries(body))
      end

      private

      def requested_token_limit(max_tokens)
        value = max_tokens.presence || config.max_tokens
        value = value.to_i
        value = config.max_tokens if value <= 0
        value.clamp(ProviderConfig::MAX_TOKENS_RANGE.min, ProviderConfig::MAX_TOKENS_RANGE.max)
      end

      # Drop optional parameters some providers reject (reasoning, temperature).
      def request_with_compat_retries(body)
        request(body)
      rescue Error => e
        if e.message.match?(/HTTP 400.*reasoning/i) && body.key?(:reasoning)
          return request_with_compat_retries(body.except(:reasoning))
        end
        raise unless e.message.match?(/HTTP 400.*temperature/i)

        request(body.except(:temperature))
      end

      def request(body)
        response = http.post(config.chat_url, headers: config.headers, json: body)
        if defined?(::HTTPX::ErrorResponse) && response.is_a?(::HTTPX::ErrorResponse)
          fail!(response.error.class.name.demodulize)
        end
        length = Array(response.headers["content-length"]).first.to_i
        fail!(I18n.t("test_management.assistant.errors.response_too_large")) if length > MAX_RESPONSE_BYTES
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

        content = message_content(message["content"])
        calls = tool_calls(message["tool_calls"])
        finish_reason = json.dig("choices", 0, "finish_reason")
        if content.blank? && calls.empty?
          fail!(empty_content_error(json, finish_reason))
        end

        Response.new(content:, tool_calls: calls, finish_reason:, usage: self.class.normalize_usage(json["usage"]))
      rescue JSON::ParserError
        fail!(I18n.t("test_management.assistant.errors.unexpected_response"))
      end

      def message_content(raw)
        case raw
        when String then raw
        when Array
          raw.filter_map do |part|
            next part if part.is_a?(String)
            next unless part.is_a?(Hash)

            part["text"].presence || part.dig("text", "value")
          end.join
        end
      end

      def empty_content_error(json, finish_reason)
        tokens = json.dig("usage", "completion_tokens_details", "reasoning_tokens").presence ||
                 json.dig("usage", "completion_tokens")
        if finish_reason.to_s == "length" && tokens.to_i.positive?
          return I18n.t("test_management.assistant.errors.reasoning_exhausted", tokens: tokens.to_i)
        end

        I18n.t("test_management.assistant.errors.empty_reply")
      end

      def parse_anthropic(text)
        AnthropicAdapter.parse(JSON.parse(text)) || fail!(I18n.t("test_management.assistant.errors.unexpected_response"))
      rescue JSON::ParserError
        fail!(I18n.t("test_management.assistant.errors.unexpected_response"))
      end

      def tool_calls(raw)
        Array(raw).filter_map do |call|
          function = call.is_a?(Hash) ? call["function"] : nil
          next unless function.is_a?(Hash) && function["name"].is_a?(String)

          arguments = function["arguments"]
          arguments = begin
            arguments.is_a?(String) ? JSON.parse(arguments.presence || "{}") : arguments
          rescue JSON::ParserError
            {}
          end
          ToolCall.new(id: call["id"].to_s.presence || SecureRandom.hex(6), name: function["name"],
                       arguments: arguments.is_a?(Hash) ? arguments : {})
        end
      end

      def http_error(status, text)
        detail = begin
          parsed = JSON.parse(text)
          error = parsed.is_a?(Hash) ? parsed["error"] : nil
          error.is_a?(Hash) ? error["message"] : error
        rescue JSON::ParserError
          nil
        end
        hint = status == 429 ? I18n.t("test_management.assistant.errors.rate_limited") : nil
        ["HTTP #{status}", detail.is_a?(String) ? detail.first(300) : nil, hint].compact.join(": ")
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
