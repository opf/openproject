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
  # A proposed change in an answer of an AI Assistance conversation: a finding with evidence,
  # or a plain change that the user asked for. Applied or dismissed on its own.
  class AssistantProposal < ApplicationRecord
    include AI::Proposal

    belongs_to :message, class_name: "AI::AssistantChatMessage", inverse_of: :proposals

    enum :source, { rule: "rule", ai: "ai" }, validate: true
    enum :severity, { high: "high", medium: "medium", low: "low" }, validate: { allow_nil: true }
    enum :dismiss_reason, {
      wrong: "wrong",
      not_relevant: "not_relevant",
      already_known: "already_known"
    }, validate: { allow_nil: true }, prefix: :dismissed_as

    # Findings first, by severity; plain proposals last.
    scope :by_severity, -> {
      unscope(:order).order(Arel.sql("CASE severity WHEN 'high' THEN 0 WHEN 'medium' THEN 1 WHEN 'low' THEN 2 ELSE 3 END"),
                            :position, :id)
    }

    delegate :chat, to: :message

    # A finding has a severity and evidence; a plain proposal is only a change with a short text.
    def finding? = severity.present?

    def proposal_work_package = chat.work_package

    def proposal_user = chat.user

    def proposal_changeable_attributes = chat.skill.changeable_attributes

    def proposal_journal_cause = Journal::CausedByAssistantChat.new(proposal: self)

    def proposal_siblings
      AI::AssistantProposal.open.joins(:message).where(ai_assistant_chat_messages: { chat_id: message.chat_id })
    end
  end
end
