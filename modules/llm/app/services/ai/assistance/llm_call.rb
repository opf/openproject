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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module Assistance
    # One structured call to the model for a run or a chat answer. The request, the answer
    # and a failure become events on the record (its "Details"), and one log line each
    # (tag "AI Assistance"). Prompts and answers hold user content, so the full text is
    # logged at debug level only.
    class LlmCall
      attr_reader :record, :log_tag

      def initialize(record:, log_tag:)
        @record = record
        @log_tag = log_tag
      end

      # history: earlier turns as [role, content] pairs, oldest first.
      # temperature: nil keeps the provider default.
      # llm: a ready Llm::Runtime::Resolution.
      # tools: RubyLLM tools, built with #tool_calls.
      def ask(llm:, system:, message:, schema:, history: [], temperature: nil, tools: [])
        log_request(llm:, system:, message:, history:, temperature:, tools:)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        answer = build_chat(llm:, system:, history:, temperature:, tools:).with_schema(schema).ask(message)
        log_answer(answer, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1))

        Llm::StructuredOutput.parse!(answer)
      end

      # An error outside the LLM (a bug) is logged as an error, with its backtrace.
      def record_failure(error)
        level = error.is_a?(Llm::Errors::Error) ? :warn : :error
        log(level, "failed: #{error.class}: #{failure_text(error)}")
        log(:debug, Array(error.backtrace).first(15).join("\n")) if level == :error
        record.log_event(:failure, error: error.class.name, message: failure_text(error))
      end

      def tool_calls
        @tool_calls ||= AI::Assistance::ToolCalls.new(self)
      end

      def log(level, text)
        Rails.logger.tagged("AI Assistance", log_tag) { Rails.logger.public_send(level, text) }
      end

      private

      def log_request(llm:, system:, message:, history:, temperature:, tools:)
        log(:info, "asking model=#{llm.model_id} system=#{system.size}c message=#{message.size}c " \
                   "turns=#{history.size} tools=#{tools.size}")
        log(:debug, "system prompt:\n#{system}\nmessage:\n#{message}")
        record.log_event(:request, model: llm.model_id, temperature:, system:, message:, tools: tools.size)
      end

      def log_answer(answer, seconds)
        content = answer.respond_to?(:content) ? answer.content : answer
        log(:info, "answered in #{seconds}s after #{tool_calls.count} tool calls")
        log(:debug, "answer:\n#{content.inspect}")
        record.log_event(:answer, seconds:, tool_calls: tool_calls.count,
                                  content: content.is_a?(String) ? content : JSON.pretty_generate(content))
      end

      def build_chat(llm:, system:, history:, temperature:, tools:)
        chat = llm.chat.with_instructions(system)
        chat.with_temperature(temperature) unless temperature.nil?
        if tools.any?
          chat.with_tools(*tools)
          chat.on_end_message { |reply| record_thought(reply) }
        end
        history.each { |role, content| chat.add_message(role:, content:) }
        chat
      end

      # The model's text or reasoning on a turn that calls tools: why it calls them.
      def record_thought(reply)
        return unless reply&.tool_call?

        content = reply.content.respond_to?(:text) ? reply.content.text : reply.content
        text = content.presence || reply.thinking&.text
        record.log_event(:thought, text: text.to_s.strip) if text.present?
      end

      # Llm::Errors.wrap raises with the original error as the cause.
      def failure_text(error)
        cause = error.cause && "\nCaused by #{error.cause.class}: #{error.cause.message}"
        "#{error.message}#{cause}".truncate(2_000)
      end
    end
  end
end
