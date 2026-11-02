# frozen_string_literal: true

module TestManagement
  module Assistant
    # Answers one chat message (ChatJob, as the user). Up to MAX_ROUNDS model calls: read tools
    # run server-side and their results go back to the model as data; the first write tool call
    # ends the turn with a proposal that waits for the user's confirmation.
    #
    # Models without native tool calling can answer with a JSON envelope instead:
    #   {"tool": "<name>", "arguments": {...}}  or plain text for an answer.
    class ChatService
      MAX_ROUNDS = 4
      HISTORY = 12

      # client: defaults to the provider and model remembered on the message (0021).
      def initialize(message:, client: nil)
        @message = message
        @client = client || Client.new(config: ProviderChoice.for_record(message).config)
        @prompt = Prompt.new
        @envelope = false
      end

      def call
        message.update!(provider_model: client.config.display_label)
        conversation = messages
        MAX_ROUNDS.times do
          reply = ask(conversation)
          calls = @envelope ? envelope_calls(reply.content) : reply.tool_calls
          calls = envelope_calls(reply.content) if calls.empty? && !@envelope
          return finish(reply.content) if calls.empty?

          write = calls.find { Tools.write?(it.name) }
          return propose(write, reply.content) if write

          conversation.concat(tool_round(reply, calls))
        end
        finish(I18n.t("test_management.assistant.chat.too_many_steps"))
      rescue Client::Error => e
        message.update!(state: "failed", content: e.message.first(1000))
      end

      def messages
        [{ role: "system", content: system_prompt },
         *history,
         { role: "user", content: current_user_content }]
      end

      private

      attr_reader :message, :client, :prompt

      def ask(conversation)
        client.chat(messages: conversation, tools: @envelope ? nil : Tools.schemas)
      rescue Client::Error => e
        # Some OpenAI-compatible servers reject the tools parameter for models without tool support.
        raise unless !@envelope && e.message.match?(/HTTP 4\d\d.*tool/i)

        @envelope = true
        client.chat(messages: conversation)
      end

      def tool_round(reply, calls)
        results = calls.first(5).map do |call|
          data = if Tools.read?(call.name)
                   Tools.run(call.name, call.arguments, user: message.user,
                                                        project: message.project)
                 else
                   { error: "unknown tool" }.to_json
                 end
          [call, prompt.fence("result of #{call.name}", data, limit: 20_000)]
        end
        if @envelope || reply.tool_calls.empty?
          [{ role: "assistant", content: reply.content.to_s },
           { role: "user", content: "Tool results:\n#{results.map(&:last).join("\n")}\nNow answer the question." }]
        else
          [{ role: "assistant", content: reply.content,
             tool_calls: calls.map do |c|
               { id: c.id, type: "function", function: { name: c.name, arguments: c.arguments.to_json } }
             end },
           *results.map { |call, text| { role: "tool", tool_call_id: call.id, content: text } }]
        end
      end

      def envelope_calls(content)
        parsed = Prompt.extract_json(content)
        return [] unless parsed.is_a?(Hash) && parsed["tool"].is_a?(String)
        return [] unless Tools.read?(parsed["tool"]) || Tools.write?(parsed["tool"])

        [Client::ToolCall.new(id: SecureRandom.hex(6), name: parsed["tool"],
                              arguments: parsed["arguments"].is_a?(Hash) ? parsed["arguments"] : {})]
      end

      def finish(content)
        text = Prompt.clean(content).strip.first(TestManagement::AssistantMessage::MAX_CONTENT)
        message.update!(state: "done", content: text.presence || I18n.t("test_management.assistant.chat.empty_answer"))
      end

      def propose(call, content)
        action = Actions.propose(call.name, call.arguments, user: message.user, project: message.project)
        intro = Prompt.clean(content).strip.first(TestManagement::AssistantMessage::MAX_CONTENT)
        intro = nil if Prompt.extract_json(intro).is_a?(Hash)
        message.update!(state: "done", content: intro.presence || I18n.t("test_management.assistant.chat.proposal_intro"),
                        action:, action_status: "proposed")
      end

      def history
        earlier = TestManagement::AssistantMessage.of(message.user, message.project)
                    .where(id: ...message.id).where(state: "done").order(id: :desc).limit(HISTORY + 1).to_a.reverse
        earlier.pop if earlier.last && earlier.last.role == "user" # the current question, sent separately
        earlier.last(HISTORY).map do |m|
          content = m.content.to_s
          if m.proposal?
            content += "\n[Proposed #{m.action_data['name']}: #{Array(m.action_data['preview']).first} – #{m.action_status}]"
          end
          { role: m.role, content: }
        end
      end

      def current_user_content
        question = TestManagement::AssistantMessage.of(message.user, message.project)
                     .where(id: ...message.id, role: "user").order(id: :desc).first
        question&.content.to_s
      end

      def system_prompt
        <<~TEXT
          You are the test assistant of a test management module in OpenProject. You help the user
          with their project's test cases, test runs and results, milestones and work package coverage.
          Answer briefly in plain text (no HTML, no Markdown tables) in the user's language. Use the
          read tools to look things up instead of guessing; if you cannot find something, say so.
          To create a test run, a milestone or test cases, call the matching create_* tool: the
          user then sees a confirmation card, and nothing is created until they confirm. Never
          claim that something was created. Refer to items by name and id; do not output links.
          If you cannot call tools natively, reply with only {"tool":"<name>","arguments":{...}}.
          #{prompt.rules}

          #{prompt.fence('project overview', ChatContext.new(user: message.user, project: message.project).to_text, limit: 20_000)}
        TEXT
      end
    end
  end
end
