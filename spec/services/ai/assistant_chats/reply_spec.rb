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

RSpec.describe AI::AssistantChats::Reply, with_flag: { ai_assistance: true } do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project, enabled_internal_comments: true) }
  shared_let(:user) do
    create(:user, language: "de", member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end

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
    allow(llm).to receive(:with_tools) { |*tools| (sent[:tools] = tools) && llm }
    allow(llm).to receive(:add_message) { |role:, content:| (sent[:history] ||= []) << [role, content] }
    allow(llm).to receive(:ask) do |text|
      sent[:user] = text
      instance_double(RubyLLM::Message, content: answer.deep_stringify_keys)
    end
    create(:work_package_journal, journable: work_package, user:, notes: "Public note", version: 2)
    create(:work_package_journal, journable: work_package, user:, notes: "Secret note", version: 3, internal: true)
  end

  def ask(content)
    User.execute_as(user) do
      I18n.with_locale(:de) do
        answer_message = AI::AssistantChats::SendMessageService.new(chat: chat.reload, user:).call(content).result
        described_class.new(answer_message).call
        answer_message.reload
      end
    end
  end

  def start
    User.execute_as(user) do
      I18n.with_locale(:de) do
        answer_message = AI::AssistantChats::SendMessageService.new(chat: chat.reload, user:).start.result
        described_class.new(answer_message).call
        answer_message.reload
      end
    end
  end

  describe "a start of the skill" do
    it "sends the fixed request in the answer's locale, as a user turn" do
      start
      start

      request = I18n.t("ai_assistance.chat.start_request", locale: :de)
      expect(sent[:user]).to eq(request)
      expect(sent[:history].first).to eq([:user, request])
    end
  end

  describe "an answer with findings and plain proposals" do
    let(:answer) do
      { answer: "Zwei Befunde.", proposals: [
        { severity: "medium", area: "content", text: "Der Kommentar ändert den Umfang.",
          evidence: ["Public note"], changes: [{ field: "description", value: "New text" }] },
        { severity: "low", area: "content", text: "Ohne Beleg.", evidence: [], changes: [] },
        { severity: "none", area: "none", text: "Neuer Betreff", evidence: [],
          changes: [{ field: "subject", value: "New subject" }] },
        { severity: "none", area: "none", text: "Keine gültige Änderung", evidence: [],
          changes: [{ field: "status", value: "No such status" }] }
      ] }
    end

    it "stores the findings with evidence and the plain proposals with a valid change" do
      message = ask("What is missing?")

      expect(message).to be_done
      expect(message.content).to eq("Zwei Befunde.")
      finding, plain = message.proposals.to_a
      expect(finding).to have_attributes(severity: "medium", base_lock_version: work_package.lock_version,
                                         change_set: AI::Proposal.change_set_for({ "description" => "New text" }))
      expect(plain).to have_attributes(severity: nil, text: "Neuer Betreff")
      expect(message.proposals.size).to eq(2)
      expect(message.events.pluck("kind")).to include("request", "answer", "stored")
    end

    it "sends the visible context in the system prompt, at a low temperature" do
      ask("What is missing?")

      expect(sent[:system]).to include("Context (JSON)", "Public note", AI::Assistance::OutputRules::PROPOSALS,
                                       %(locale code "de"))
      expect(sent[:system]).not_to include("Secret note")
      expect(sent[:user]).to eq("What is missing?")
      expect(sent[:temperature]).to eq(described_class::TEMPERATURE)
    end

    it "tells the model what it proposed before" do
      ask("What is missing?")
      ask("And now?")

      expect(sent[:history].last.last).to include("Proposals:", "- Der Kommentar ändert den Umfang. (open)")
    end
  end

  describe "the MCP tools" do
    it "offers the read-only MCP tools and explains them" do
      ask("How many?")

      expect(sent[:tools].map(&:name)).to include("search_work_packages", "count_work_packages")
      expect(sent[:tools].map(&:name)).not_to include("update_work_package")
      expect(sent[:system]).to include(AI::Assistance::OutputRules::TOOLS, %("id":#{project.id}))
    end

    context "when the model calls a tool" do
      before do
        allow(llm).to receive(:ask) do
          sent[:tools].find { it.name == "count_work_packages" }.call({ "project_id" => project.id })
          instance_double(RubyLLM::Message, content: { "answer" => "One.", "proposals" => [] })
        end
      end

      it "runs it as the user and records it" do
        message = ask("How many?")

        expect(message.content).to eq("One.")
        tool_call = message.events.find { it["kind"] == "tool_call" }
        expect(tool_call["data"]).to include("name" => "count_work_packages", "arguments" => { "project_id" => project.id })
        expect(message.events.find { it["kind"] == "answer" }["data"]).to include("tool_calls" => 1)
      end
    end

    context "when the model calls tools without end" do
      before do
        allow(llm).to receive(:ask) do
          tool = sent[:tools].find { it.name == "count_work_packages" }
          (AI::Assistance::ToolCalls::HARD_LIMIT + 1).times { |page| tool.call({ "project_id" => page }) }
        end
      end

      it "fails the answer" do
        message = ask("How many?")

        expect(message).to be_failed
        expect(message.events.last["data"]).to include("error" => "AI::Assistance::ToolCalls::Exceeded")
      end
    end

    context "when the model cannot call functions" do
      before do
        connection = create(:llm_connection)
        LlmCapabilityVerdict.create!(llm_connection: connection, model_id: "test-model", capability: "function_calling",
                                     state: "unsupported", source: "admin", checked_at: Time.current)
        allow(LlmConnection.active_connection).to receive(:capability_verdicts)
          .and_return(LlmCapabilityVerdict.where(llm_connection: connection))
      end

      it "offers no tools and does not mention them" do
        ask("How many?")

        expect(sent).not_to have_key(:tools)
        expect(sent[:system]).not_to include(AI::Assistance::OutputRules::TOOLS)
      end
    end
  end

  context "when the model fails" do
    before { allow(llm).to receive(:ask).and_raise(Llm::Errors::TimeoutError, "slow") }

    it "fails the answer" do
      expect(ask("Hello")).to be_failed
    end
  end

  context "without a model" do
    before { allow(LlmConnection.active_connection).to receive(:default_model_for).and_return(nil) }

    it "fails the answer" do
      expect(ask("Hello")).to be_failed
    end
  end
end
