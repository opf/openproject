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

      attr_reader :message

      def initialize(message)
        @message = message
      end

      def call
        answer = ask
        store_proposals(Array(answer[:proposals]))
        message.update!(content: answer[:answer].to_s.strip.presence || I18n.t("ai_assistance.chat.empty_answer"),
                        status: "done")
        llm_call.log(:info, "answered with #{message.proposals.count} proposals")
      rescue StandardError => e
        fail_reply(e)
      end

      private

      def chat = message.chat

      def work_package = chat.work_package

      def user = chat.user

      def skill = chat.skill

      def ask
        system = skill.system_prompt(locale: message.locale)
        raise Llm::Errors::NotReady, "no system prompt" if system.blank?
        raise Llm::Errors::NotReady, llm.status unless llm.ready?

        history = earlier_turns
        question = history.pop
        llm_call.ask(llm:, system: "#{system}\n\nContext (JSON):\n#{context_json}",
                     message: question&.content.to_s, schema: answer_format.schema, temperature: TEMPERATURE,
                     history: history.map { |turn| [turn.from_user? ? :user : :assistant, turn_text(turn)] })
      end

      # The finished turns before this answer, oldest first, ending with the question.
      def earlier_turns
        chat.messages.includes(:proposals).where(id: ...message.id).where(status: "done").last(MAX_TURNS).to_a
      end

      # An earlier answer with its proposals, so that the model knows what it proposed.
      def turn_text(turn)
        return turn.content.to_s if turn.from_user? || turn.proposals.empty?

        lines = turn.proposals.map do |proposal|
          "- #{proposal.text.presence || proposal.change_actions.pluck('key').join(', ')} (#{proposal.state})"
        end
        [turn.content.presence, "Proposals:\n#{lines.join("\n")}"].compact.join("\n\n")
      end

      def context_json
        AI::Assistance::WorkPackageContext.new(work_package:, user:).to_h
                                             .merge(change_options: change_options.for_prompt)
                                             .to_json
      end

      def store_proposals(raw_proposals)
        kept, dropped = raw_proposals.first(MAX_PROPOSALS).map { |raw| [raw, answer_format.proposal_attributes(raw)] }
                                     .partition { |_raw, attributes| attributes }
        kept.each_with_index do |(_raw, attributes), index|
          message.proposals.create!(attributes.merge(position: index, base_lock_version: message.base_lock_version))
        end
        return if raw_proposals.empty?

        message.log_event(:stored, findings: raw_proposals.size, stored: kept.size, dropped: dropped.map { |raw, _| raw.to_h })
      end

      def llm
        @llm ||= skill.assistant.llm_resolution
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
        message.update!(status: "failed", content: "")
      rescue StandardError => e
        llm_call.log(:error, "could not mark the answer as failed: #{e.class}: #{e.message}")
      end

      def llm_call
        @llm_call ||= AI::Assistance::LlmCall.new(record: message, log_tag: "chat #{chat.id}")
      end
    end
  end
end
