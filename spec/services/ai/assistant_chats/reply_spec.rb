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

require "spec_helper"

RSpec.describe AI::AssistantChats::Reply do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project, enabled_internal_comments: true) }
  shared_let(:user) do
    create(:user, language: "de", member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  shared_let(:closed_status) { create(:closed_status) }

  let(:work_package) { create(:work_package, project:, subject: "Old subject", description: "Old text") }
  let(:skill) { create(:ai_assistant_skill, prompt: "Check it.") }
  let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package:) }
  let(:answer) { { answer: "", proposals: [] } }
  let(:llm) { instance_double(RubyLLM::Chat) }
  let(:sent) { {} }

  before do
    allow(Llm::Session).to receive(:for).and_return(instance_double(Llm::Session, chat: llm))
    allow(llm).to receive(:with_instructions) { |text| (sent[:system] = text) && llm }
    allow(llm).to receive(:with_temperature) { |value| (sent[:temperature] = value) && llm }
    allow(llm).to receive(:with_schema) { |schema| (sent[:schema] = schema) && llm }
    allow(llm).to receive(:add_message) { |role:, content:| (sent[:history] ||= []) << [role, content] }
    allow(llm).to receive(:ask) do |text|
      sent[:user] = text
      instance_double(RubyLLM::Message, content: answer.deep_stringify_keys)
    end
    create(:work_package_journal, journable: work_package, user:, notes: "Public note", version: 2)
    create(:work_package_journal, journable: work_package, user:, notes: "Secret note", version: 3, internal: true)
  end

  def ask(content)
    chat.messages.create!(role: "user", content:)
    answer_message = chat.messages.create!(role: "assistant", status: "pending", locale: "de",
                                           base_lock_version: work_package.reload.lock_version)
    User.execute_as(user) { described_class.new(answer_message).call }
    answer_message.reload
  end

  describe "the first answer of a skill with findings" do
    before { create(:work_package, project:, parent: work_package, status: closed_status) }

    let(:answer) do
      { answer: "Zwei Befunde.", proposals: [
        { severity: "medium", area: "content", text: "Der Kommentar ändert den Umfang.",
          evidence: ["Public note"], changes: [{ field: "description", value: "New text" }] },
        { severity: "low", area: "content", text: "Ohne Beleg.", evidence: [], changes: [] }
      ] }
    end

    it "stores the rule findings and the AI findings with evidence as proposals" do
      message = ask("Refresh work package")

      expect(message).to be_done
      expect(message.content).to eq("Zwei Befunde.")
      expect(message.proposals.rule.pluck(:rule_key)).to eq(%w[open_with_all_descendants_closed])
      ai = message.proposals.ai.sole
      expect(ai).to have_attributes(severity: "medium", change_set: AI::Proposal.change_set_for({ "description" => "New text" }),
                                    base_lock_version: work_package.lock_version)
      expect(message.events.pluck("kind")).to include("rules", "request", "answer", "stored")
    end

    it "sends the visible context and the rule findings, at a low temperature" do
      ask("Refresh work package")

      expect(sent[:user]).to include("Public note", "rule_findings")
      expect(sent[:user]).not_to include("Secret note")
      expect(sent[:system]).to include("sum up the findings", %(locale code "de"))
      expect(sent[:temperature]).to eq(described_class::FINDINGS_TEMPERATURE)
    end

    context "when the model fails" do
      before { allow(llm).to receive(:ask).and_raise(Llm::Errors::TimeoutError, "slow") }

      it "keeps the rule findings and lists the AI review as not checked" do
        message = ask("Refresh work package")

        expect(message).to be_done
        expect(message.proposals.rule.count).to eq(1)
        expect(message.not_checked).to include("area" => "ai_review", "reason" => "failed")
      end
    end

    context "without a system prompt" do
      let(:skill) { create(:ai_assistant_skill, prompt: "") }

      it "answers with the rule findings only" do
        message = ask("Refresh work package")

        expect(message).to be_done
        expect(message.proposals.rule.count).to eq(1)
        expect(message.not_checked).to include("area" => "ai_review", "reason" => "no_prompt")
        expect(llm).not_to have_received(:ask)
      end
    end
  end

  describe "a free answer" do
    let(:skill) { create(:ai_assistant_skill, :chat, prompt: "Answer questions.") }
    let(:answer) do
      { answer: "Hier sind zwei Vorschläge.", proposals: [
        { text: "Neuer Betreff", changes: [{ field: "subject", value: "New subject" }] },
        { text: "Keine gültige Änderung", changes: [{ field: "status", value: "No such status" }] }
      ] }
    end

    it "stores each proposal with a valid change, and the context in the system prompt" do
      message = ask("Make it clearer")

      expect(message.content).to eq("Hier sind zwei Vorschläge.")
      expect(message.proposals.sole).to have_attributes(text: "Neuer Betreff", severity: nil, source: "ai")
      expect(sent[:system]).to include("Context (JSON)", %(Put proposed changes in "proposals"))
      expect(sent[:temperature]).to be_nil
    end

    it "tells the model what it proposed before" do
      ask("Make it clearer")
      ask("And now?")

      expect(sent[:history].last.last).to include("Proposals:", "- Neuer Betreff (open)")
    end

    context "without a model" do
      before { allow(LlmConnection.active_connection).to receive(:default_chat_model).and_return(nil) }

      it "fails the answer" do
        expect(ask("Hello")).to be_failed
      end
    end
  end
end
