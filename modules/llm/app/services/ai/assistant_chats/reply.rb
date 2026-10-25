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
    # Answers the latest message of a conversation, as the conversation's user. The model gets
    # the skill's system prompt, the work package context, the earlier turns and the question,
    # and answers with text and 0..n proposals (AI::Assistance::AnswerFormat). Any failure
    # marks the answer as failed, so the dialog never waits forever.
    class Reply
      MAX_TURNS = 20
      MAX_PROPOSALS = 15
      # Low, so that one work package gives the same answer from run to run.
      TEMPERATURE = 0.2
      RETRY = "None of your proposals can be stored. The reason for each proposal: %s. Answer again in the " \
              "same format, and fix this. A finding needs evidence and a text; a plain proposal needs a valid change."

      attr_reader :message

      def initialize(message)
        @message = message
      end

      def call
        answer = ask
        reasons = lost_proposal_reasons(answer)
        answer = ask_again(answer, reasons) if reasons
        finish { store_answer(answer) }
      rescue StandardError => e
        fail_reply(e)
      end

      private

      def chat = message.chat

      def work_package = chat.work_package

      def user = chat.user

      def skill = chat.skill

      def ask(correction: [])
        ensure_ready!
        *history, (_, question) = turns + correction
        llm_call.ask(llm:, system: "#{system_prompt}\n\nContext (JSON):\n#{context_json}",
                     message: question.to_s, schema: answer_format.schema, temperature: TEMPERATURE, tools:, history:)
      end

      def ensure_ready!
        raise Llm::Errors::NotReady, llm.status unless llm.ready?
        raise Llm::Errors::NotReady, "no system prompt" if system_prompt.blank?
      end

      def turns
        earlier_turns.map { |turn| [turn.from_assistant? ? :assistant : :user, turn_text(turn)] }
      end

      # The reason for each proposal, when the answer has proposals and none of them qualifies.
      def lost_proposal_reasons(answer)
        return unless work_package

        results = Array(answer[:proposals]).first(MAX_PROPOSALS).map { |raw| answer_format.evaluate(raw) }
        results.map(&:last) if results.any? && results.none?(&:first)
      end

      def ask_again(answer, reasons)
        llm_call.log(:info, "asking again: all #{reasons.size} proposals were dropped")
        list = reasons.each_with_index.map { |reason, index| "#{index + 1}: #{reason}" }.join(", ")
        ask(correction: [[:assistant, answer.to_json], [:user, format(RETRY, list)]])
      end

      def system_prompt
        @system_prompt ||= skill.system_prompt(locale: message.locale, tools: tools.any?, work_package: work_package.present?)
      end

      # The finished turns before this answer, oldest first, ending with the question.
      def earlier_turns
        chat.messages.includes(:proposals).where(id: ...message.id).where(status: "done").last(MAX_TURNS).to_a
      end

      # A start is a fixed request. An earlier answer comes with its proposals, so that the
      # model knows what it proposed.
      def turn_text(turn)
        return start_request_text if turn.from_start?
        return turn.content.to_s if turn.from_user? || turn.proposals.empty?

        lines = turn.proposals.map { |proposal| proposal_line(proposal) }
        [turn.content.presence, "Proposals:\n#{lines.join("\n")}"].compact.join("\n\n")
      end

      def start_request_text
        I18n.t("ai_assistance.chat.start_request", locale: message.locale)
      end

      def proposal_line(proposal)
        "- #{proposal.text.presence || proposal.change_actions.pluck('key').join(', ')} (#{proposal.state})"
      end

      # Off a work package, the user and the project of the page, and nothing to change.
      def context_json
        return AI::Assistance::PlaceContext.new(project: chat.project, user:).to_h.to_json unless work_package

        AI::Assistance::WorkPackageContext.new(work_package:, user:).to_h
                                          .merge(change_options: change_options.for_prompt)
                                          .to_json
      end

      # Stores the result only while the answer is still pending. A result after the timeout
      # (fail_stale_answers!) is dropped, because the user may have asked again.
      def finish
        AI::AssistantChatMessage.transaction do
          message.reload(lock: true)
          next message.log_event(:late) unless message.pending?

          yield
        end
      end

      def store_answer(answer)
        store_proposals(work_package ? Array(answer[:proposals]) : [])
        message.update!(content: answer[:answer].to_s.strip.presence || I18n.t("ai_assistance.chat.empty_answer"),
                        status: "done")
        llm_call.log(:info, "answered with #{message.proposals.count} proposals")
      end

      def store_proposals(raw_proposals)
        kept, dropped = raw_proposals.first(MAX_PROPOSALS).map { |raw| [*answer_format.evaluate(raw), raw] }
                                     .partition(&:first)
        answer_format.sort(kept.map(&:first)).each_with_index { |attributes, position| store_proposal(attributes, position) }
        log_stored(raw_proposals.size, kept.size, dropped) if raw_proposals.any?
      end

      def store_proposal(attributes, position)
        message.proposals.create!(attributes.merge(position:, base_lock_version: message.base_lock_version))
      end

      def log_stored(findings, stored, dropped)
        message.log_event(:stored, findings:, stored:,
                                   dropped: dropped.map { |_, reason, raw| { reason:, proposal: raw.to_h } })
      end

      def llm
        @llm ||= skill.assistant.llm_resolution
      end

      # The read-only MCP tools, unless the skill opts out or the model is known not to call functions.
      def tools
        @tools ||= if !skill.use_tools || function_calling_unsupported?
                     []
                   else
                     AI::Assistance::McpTool.read_only_classes
                                            .map { |tool| AI::Assistance::McpTool.for(tool, user:, calls: llm_call.tool_calls) }
                   end
      end

      def function_calling_unsupported?
        llm.connection.capability_verdicts.for_model(llm.model_id).for_capability(:function_calling).unsupported.exists?
      end

      def change_options
        @change_options ||= AI::Assistance::ChangeOptions.new(keys: skill.changeable_attributes, work_package:, user:)
      end

      def answer_format
        @answer_format ||= AI::Assistance::AnswerFormat.new(AI::Assistance::ProposalBuilder.new(change_options))
      end

      def fail_reply(error)
        message.reload
        llm_call.record_failure(error)
        message.update!(status: "failed", content: "") if message.pending?
      rescue StandardError => e
        llm_call.log(:error, "could not mark the answer as failed: #{e.class}: #{e.message}")
      end

      def llm_call
        @llm_call ||= AI::Assistance::LlmCall.new(record: message, log_tag: "chat #{chat.id}")
      end
    end
  end
end
