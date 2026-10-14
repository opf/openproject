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
    # Answers the latest question of a conversation, as the conversation's user.
    #
    # The first answer of a skill with findings runs the built-in checks, then asks the model
    # for findings with evidence. If the AI part cannot run or fails, the rule findings stay
    # and "Not checked" says why. Every other answer is free text with 0..n proposals, and
    # gets the earlier turns. Any other failure marks the answer as failed.
    class Reply
      MAX_TURNS = 20
      MAX_PROPOSALS = 15
      FINDINGS_TEMPERATURE = 0.2

      attr_reader :message

      def initialize(message)
        @message = message
      end

      def call
        findings_turn? ? answer_with_findings : answer_with_text
      rescue StandardError => e
        fail_reply(e)
      end

      private

      def chat = message.chat

      def work_package = chat.work_package

      def user = chat.user

      def skill = chat.skill

      def findings_turn?
        skill.findings? && chat.messages.where(role: "assistant").where(id: ...message.id).none?
      end

      # -- Findings ----------------------------------------------------------------------

      def answer_with_findings
        rule_texts = run_rules
        blocker = review_blocker
        if blocker
          message.add_not_checked(:ai_review, blocker)
          return finish(nil)
        end

        review = skill.skill_type.review_class.new(skill:, work_package:, user:, rule_findings: rule_texts)
        answer = ask_for_findings(review)
        store_findings(review, Array(answer[:proposals]))
        finish(answer[:answer])
      end

      # The rule findings are stored at once, so the dialog shows them while the AI answers.
      def run_rules
        context = skill.skill_type.build_context(work_package:, user:)
        findings = skill.rules.flat_map { |rule| rule.call(context) }
        findings.each_with_index do |finding, index|
          message.proposals.create!(finding.merge(position: index, base_lock_version: message.base_lock_version))
        end
        message.update!(not_checked: context.not_checked)
        message.log_event(:rules, findings: findings.size, review: review_blocker ? "skipped" : "started")
        findings.pluck(:text)
      end

      def review_blocker
        if skill.prompt.blank? then :no_prompt
        elsif !LlmConnection.available? then :no_llm_connection
        elsif model_id.nil? then :no_model
        end
      end

      def ask_for_findings(review)
        llm_call.ask(model_id:, system: skill.system_prompt(locale: message.locale, format: "findings"),
                     message: review.user_message, schema: review.schema, temperature: FINDINGS_TEMPERATURE)
      rescue StandardError => e
        llm_call.record_failure(e)
        message.add_not_checked(:ai_review, :failed)
        {}
      end

      def store_findings(review, raw_findings)
        offset = message.proposals.count
        kept, dropped = raw_findings.first(MAX_PROPOSALS).map { |raw| [raw, review.finding_attributes(raw)] }
                                    .partition { |_raw, attributes| attributes }
        kept.each_with_index do |(_raw, attributes), index|
          message.proposals.create!(attributes.merge(source: "ai", position: offset + index,
                                                     base_lock_version: message.base_lock_version))
        end
        return if raw_findings.empty?

        message.log_event(:stored, findings: raw_findings.size, stored: kept.size, dropped: dropped.map { |raw, _| raw.to_h })
      end

      # -- Free text ---------------------------------------------------------------------

      def answer_with_text
        system = skill.system_prompt(locale: message.locale, format: "text")
        raise Llm::Errors::NotReady, "no chat prompt" if system.blank?
        raise Llm::Errors::NotReady, "no model" unless model_id

        history = earlier_turns
        question = history.pop
        answer = llm_call.ask(model_id:, system: "#{system}\n\nContext (JSON):\n#{context_json}",
                              message: question&.content.to_s, schema: text_schema,
                              history: history.map { |turn| [turn.from_user? ? :user : :assistant, turn_text(turn)] })
        store_text_proposals(Array(answer[:proposals]))
        finish(answer[:answer].to_s.strip.presence || I18n.t("ai_assistance.chat.empty_answer"))
      end

      # The finished turns before this answer, oldest first, ending with the question.
      def earlier_turns
        chat.messages.includes(:proposals).where(id: ...message.id).where(status: "done").last(MAX_TURNS).to_a
      end

      # An earlier answer with its proposals, so that the model knows what it proposed.
      def turn_text(turn)
        return turn.content.to_s if turn.from_user? || turn.proposals.empty?

        lines = turn.proposals.map do |proposal|
          summary = proposal.text.presence || proposal.change_actions.pluck("key").join(", ")
          "- #{summary} (#{proposal.state})"
        end
        [turn.content.presence, "Proposals:\n#{lines.join("\n")}"].compact.join("\n\n")
      end

      def context_json
        AI::Assistance::WorkPackageContext.new(work_package:, user:).to_h
                                             .merge(change_options: change_options.for_prompt)
                                             .to_json
      end

      def text_schema
        {
          type: "object",
          additionalProperties: false,
          required: %w[answer proposals],
          properties: {
            answer: { type: "string" },
            proposals: {
              type: "array",
              items: {
                type: "object",
                additionalProperties: false,
                required: %w[text changes],
                properties: { text: { type: "string" }, changes: proposal_builder.schema }
              }
            }
          }
        }
      end

      # A proposal without a valid change is not a proposal, and is dropped.
      def store_text_proposals(raw_proposals)
        raw_proposals.first(MAX_PROPOSALS).each_with_index do |raw, index|
          raw = raw.to_h.stringify_keys
          change_set = proposal_builder.build(raw["changes"])
          next unless change_set

          message.proposals.create!(source: "ai", position: index, text: raw["text"].to_s.strip.truncate(1_000).presence,
                                    change_set:, base_lock_version: message.base_lock_version)
        end
      end

      # -- Shared ------------------------------------------------------------------------

      def finish(content)
        message.update!(content: content.to_s.strip, status: "done")
        llm_call.log(:info, "answered with #{message.proposals.count} proposals")
      end

      def model_id
        @model_id ||= skill.assistant.effective_model_id
      end

      def change_options
        @change_options ||= AI::Assistance::ChangeOptions.new(keys: skill.changeable_attributes, work_package:, user:)
      end

      def proposal_builder
        @proposal_builder ||= AI::Assistance::ProposalBuilder.new(change_options)
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
