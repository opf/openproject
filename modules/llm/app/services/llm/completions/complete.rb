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

module Llm
  module Completions
    # The client must send thinking blocks back unchanged with their assistant turn:
    # providers reject a tool loop that drops them.
    class Complete
      FEATURE = :api_completions
      TIMEOUT = 120

      Result = Data.define(:content, :tool_calls, :thinking, :model_id, :input_tokens, :output_tokens)

      def initialize(user:, request:)
        @user = user
        @request = request
      end

      # @return [Result]
      # @raise [Llm::Errors::Error]
      def call
        resolution = Llm::Runtime.for(FEATURE)
        chat = build_chat(resolution)
        history_size = chat.messages.size
        chat.complete

        answer = chat.messages.drop(history_size).find { |message| message.role == :assistant }
        raise Llm::Errors::ParseError, "The model gave no answer" unless answer

        result(answer, resolution.model_id).tap { |completion| log(completion) }
      end

      private

      attr_reader :user, :request

      def build_chat(resolution)
        chat = resolution.chat(timeout: TIMEOUT, max_retries: 0)
        chat.with_instructions(request.system) if request.system.present?
        chat.with_tools(*client_tools) if request.tools.any?
        add_history(chat)
        chat
      end

      def client_tools = request.tools.map { |tool| ClientTool.new(tool) }

      def add_history(chat)
        request.messages.each { |message| chat.add_message(ruby_llm_message(message)) }
      end

      def ruby_llm_message(message)
        case message.role
        when "assistant" then assistant_message(message)
        when "tool" then { role: :tool, content: message.content, tool_call_id: message.tool_call_id }
        else { role: :user, content: message.content }
        end
      end

      def assistant_message(message)
        tool_calls = message.tool_calls.to_h do |call|
          [call.id, RubyLLM::ToolCall.new(id: call.id, name: call.name, arguments: call.arguments)]
        end
        thinking = message.thinking && RubyLLM::Thinking.build(text: message.thinking["text"],
                                                               signature: message.thinking["signature"])
        { role: :assistant, content: message.content, tool_calls: tool_calls.presence, thinking: }
      end

      def result(answer, model_id)
        Result.new(content: answer.content.to_s,
                   tool_calls: tool_calls_of(answer),
                   thinking: thinking_of(answer),
                   model_id: answer.model_id.presence || model_id,
                   input_tokens: answer.input_tokens,
                   output_tokens: answer.output_tokens)
      end

      def tool_calls_of(answer)
        (answer.tool_calls || {}).values.map { |call| { id: call.id, name: call.name, arguments: call.arguments || {} } }
      end

      def thinking_of(answer)
        thinking = answer.thinking
        thinking && { text: thinking.text, signature: thinking.signature }.compact
      end

      def log(completion)
        Rails.logger.info(
          "[LLM completions] user=#{user.id} model=#{completion.model_id} " \
          "messages=#{request.messages.size} tools=#{request.tools.size} " \
          "tool_calls=#{completion.tool_calls.size} " \
          "input_tokens=#{completion.input_tokens.inspect} output_tokens=#{completion.output_tokens.inspect}"
        )
      end
    end
  end
end
