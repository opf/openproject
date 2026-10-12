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
  module AssistantChats
    # Answers the latest question of a chat. The model gets the chat skill's prompt, the
    # work package context of the user, the earlier turns, and the values it may propose.
    # Any failure marks the answer as failed, so the dialog never waits forever.
    class Reply
      MAX_TURNS = 20
      MAX_ERROR_LENGTH = 255

      attr_reader :message

      def initialize(message)
        @message = message
      end

      def call
        answer = ask
        message.update!(content: answer[:answer].to_s.strip.presence || I18n.t("ai_assistance.chat.empty_answer"),
                        change_set: proposal_builder.build(answer[:changes]),
                        status: "done")
        log(:info, "answered#{' with a proposal' if message.change_set?}")
      rescue StandardError => e
        fail_reply(e)
      end

      private

      def chat = message.chat

      def work_package = chat.work_package

      def user = chat.user

      def skill = chat.skill

      def ask
        model_id = AI::AssistantRuns::ModelChoice.new(skill.assistant).model_id
        system = skill.system_prompt(locale: message.locale)
        raise Llm::Errors::NotReady, "no chat prompt" if system.blank?
        raise Llm::Errors::NotReady, "no model" unless model_id

        system = "#{system}\n\nContext (JSON):\n#{context_json}"
        history = earlier_turns
        question = history.pop
        log(:info, "asking model=#{model_id} system=#{system.size}c turns=#{history.size}")
        message.log_event(:request, model: model_id, system:, message: question&.content.to_s)

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        llm_chat = Llm::Session.for(LlmConnection.active_connection).chat(model_id).with_instructions(system)
        history.each { |turn| llm_chat.add_message(role: turn.from_user? ? :user : :assistant, content: turn.content) }
        answer = llm_chat.with_schema(schema).ask(question&.content.to_s)

        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1)
        content = answer.respond_to?(:content) ? answer.content : answer
        log(:info, "answered in #{duration}s")
        message.log_event(:answer, seconds: duration, content: content.is_a?(String) ? content : JSON.pretty_generate(content))

        Llm::StructuredOutput.parse!(answer)
      end

      # The finished turns before this answer, oldest first, ending with the question.
      def earlier_turns
        chat.messages.where(id: ...message.id).where(status: "done").last(MAX_TURNS).to_a
      end

      def context_json
        AI::AssistantRuns::WorkPackageContext.new(work_package:, user:).to_h
                                             .merge(change_options: change_options.for_prompt)
                                             .to_json
      end

      def schema
        {
          type: "object",
          additionalProperties: false,
          required: %w[answer changes],
          properties: {
            answer: { type: "string" },
            changes: proposal_builder.schema
          }
        }
      end

      def change_options
        @change_options ||= AI::AssistantRuns::ChangeOptions.new(keys: skill.changeable_attributes, work_package:, user:)
      end

      def proposal_builder
        @proposal_builder ||= AI::AssistantRuns::ProposalBuilder.new(change_options)
      end

      def fail_reply(error)
        log(error.is_a?(Llm::Errors::Error) ? :warn : :error, "failed: #{error.class}: #{error.message}")
        message.reload
        message.log_event(:failure, error: error.class.name, message: error.message.to_s.truncate(2_000))
        message.update!(status: "failed", content: "",
                        error_message: "#{error.class.name.demodulize}: #{error.message}".truncate(MAX_ERROR_LENGTH))
      rescue StandardError => e
        log(:error, "could not mark the answer as failed: #{e.class}: #{e.message}")
      end

      def log(level, text)
        Rails.logger.tagged("AI Assistance", "chat #{chat.id}") { Rails.logger.public_send(level, text) }
      end
    end
  end
end
