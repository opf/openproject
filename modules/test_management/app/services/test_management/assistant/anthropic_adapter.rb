# frozen_string_literal: true

module TestManagement
  module Assistant
    # Translates the Assistant's OpenAI-style conversation to Anthropic's native Messages API and
    # back (Client uses it for the "anthropic" preset). Anthropic's OpenAI compatibility endpoint
    # is documented as not production-ready, so the native API is used:
    #
    #   system messages            -> top-level "system"
    #   tools (OpenAI function)    -> { name, description, input_schema }
    #   assistant tool_calls       -> "tool_use" content blocks
    #   role "tool" messages       -> "tool_result" blocks in one following user turn
    #   response content[]         -> text + tool calls (Client::Response)
    #
    # No temperature is sent (newer Claude models reject non-default values); max_tokens is required.
    module AnthropicAdapter
      module_function

      def body(model:, messages:, max_tokens:, tools: nil)
        system = messages.select { role(it) == "system" }.map { text(it) }.compact_blank.join("\n\n")
        body = { model:, max_tokens:, messages: turns(messages.reject { role(it) == "system" }) }
        body[:system] = system if system.present?
        body[:tools] = tools.map { tool(it) }.compact if tools.present?
        body
      end

      def parse(json)
        blocks = json["content"]
        return nil unless blocks.is_a?(Array)

        text = blocks.select { it.is_a?(Hash) && it["type"] == "text" }.pluck("text").join("\n").presence
        calls = blocks.select { it.is_a?(Hash) && it["type"] == "tool_use" && it["name"].is_a?(String) }.map do |block|
          Client::ToolCall.new(id: block["id"].to_s.presence || SecureRandom.hex(6), name: block["name"],
                               arguments: block["input"].is_a?(Hash) ? block["input"] : {})
        end
        Client::Response.new(content: text, tool_calls: calls, finish_reason: json["stop_reason"],
                             usage: Client.normalize_usage(json["usage"]))
      end

      def tool(schema)
        function = schema.with_indifferent_access[:function] || schema.with_indifferent_access
        return nil if function[:name].blank?

        { name: function[:name], description: function[:description].to_s,
          input_schema: function[:parameters].presence || { type: "object", properties: {} } }
      end

      # Consecutive messages of the same role are merged into one turn (tool results must all be
      # in the user turn right after the assistant's tool_use blocks).
      def turns(messages)
        messages.each_with_object([]) do |message, result|
          role, blocks = convert(message)
          next if blocks.empty?

          if result.last && result.last[:role] == role
            result.last[:content].concat(blocks)
          else
            result << { role:, content: blocks }
          end
        end
      end

      def convert(message)
        case role(message)
        when "assistant"
          blocks = text_blocks(text(message))
          Array(value(message, :tool_calls)).each do |call|
            function = call.with_indifferent_access[:function] || {}
            blocks << { type: "tool_use", id: call.with_indifferent_access[:id].to_s.presence || SecureRandom.hex(6),
                        name: function[:name].to_s, input: arguments(function[:arguments]) }
          end
          ["assistant", blocks]
        when "tool"
          ["user", [{ type: "tool_result", tool_use_id: value(message, :tool_call_id).to_s, content: text(message).to_s }]]
        else
          ["user", text_blocks(text(message))]
        end
      end

      def text_blocks(text)
        text.present? ? [{ type: "text", text: }] : []
      end

      def arguments(raw)
        parsed = raw.is_a?(String) ? JSON.parse(raw.presence || "{}") : raw
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end

      def role(message) = value(message, :role).to_s

      def text(message)
        content = value(message, :content)
        content.is_a?(String) ? content : nil
      end

      def value(message, key)
        message[key] || message[key.to_s]
      end
    end
  end
end
