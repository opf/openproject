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

require "spec_helper" require_module_spec_helper

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
    allow(llm).to receive(:on_end_message) { |&block| (sent[:on_end_message] = block) && llm }
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

  describe "findings with the area none" do
    let(:answer) do
      { answer: "Zwei Befunde.", proposals: [
        { severity: "medium", area: "none", text: "Der Betreff ist veraltet.",
          evidence: ["Public note"], changes: [{ field: "subject", value: "New subject" }] },
        { severity: "low", area: "none", text: "Unklar.", evidence: ["Public note"], changes: [] },
        { severity: "low", area: "content", text: "Ohne Beleg.", evidence: [], changes: [] },
        { severity: "high", area: "status", text: "Die Beschreibung fehlt.", evidence: ["Public note"],
          changes: [{ field: "description", value: "New text" }] },
        { severity: "low", area: "tree", text: "Kein Kind.", evidence: ["Public note"], changes: [] }
      ] }
    end

    it "keeps them, with the area of the changed field, else the model's area, or none" do
      message = ask("What is missing?")

      expect(message.proposals.map { [it.severity, it.area] })
        .to contain_exactly(%w[medium content], ["low", nil], %w[high content], %w[low tree])
    end

    it "logs each dropped proposal with its reason" do
      message = ask("What is missing?")

      stored = message.events.find { it["kind"] == "stored" }["data"]
      expect(stored).to include("findings" => 5, "stored" => 4)
      expect(stored["dropped"]).to contain_exactly(include("reason" => "no evidence",
                                                           "proposal" => include("text" => "Ohne Beleg.")))
    end
  end

  describe "the order of the proposals" do
    let(:answer) do
      { answer: "Vier Befunde.", proposals: [
        { severity: "medium", area: "tree", text: "Kein Kind.", evidence: ["Public note"], changes: [] },
        { severity: "medium", area: "content", text: "Termin.", evidence: ["Public note"],
          changes: [{ field: "due_date", value: "2030-01-01" }] },
        { severity: "medium", area: "content", text: "Beschreibung.", evidence: ["Public note"],
          changes: [{ field: "description", value: "New text" }] },
        { severity: "high", area: "content", text: "Betreff.", evidence: ["Public note"],
          changes: [{ field: "subject", value: "New subject" }] },
        { severity: "medium", area: "content", text: "Inhalt.", evidence: ["Public note"], changes: [] }
      ] }
    end

    it "sorts by severity, then by the changed field, then by area" do
      message = ask("What is missing?")

      expect(message.proposals.map(&:text)).to eq(["Betreff.", "Beschreibung.", "Termin.", "Inhalt.", "Kein Kind."])
    end
  end

  describe "an answer that loses all its proposals" do
    let(:lost) do
      { answer: "Ein Befund.", proposals: [{ severity: "high", area: "status", text: "Ohne Beleg.", evidence: [], changes: [] }] }
    end
    let(:fixed) do
      { answer: "Ein Befund.", proposals: [{ severity: "high", area: "status", text: "Mit Beleg.",
                                             evidence: ["Public note"], changes: [] }] }
    end
    let(:answers) { [lost, fixed] }

    before do
      allow(llm).to receive(:ask) do |text|
        (sent[:asks] ||= []) << text
        instance_double(RubyLLM::Message, content: answers.shift.deep_stringify_keys)
      end
    end

    it "asks once more with the reason, after the dropped answer" do
      message = ask("What is missing?")

      expect(sent[:asks].size).to eq(2)
      expect(sent[:asks].last).to include("None of your proposals can be stored", "1: no evidence")
      expect(sent[:history].last).to eq([:assistant, lost.to_json])
      expect(message.proposals.map(&:text)).to eq(["Mit Beleg."])
    end

    context "when the second answer loses them too" do
      let(:answers) { [lost, lost] }

      it "does not ask a third time" do
        message = ask("What is missing?")

        expect(sent[:asks].size).to eq(2)
        expect(message).to be_done
        expect(message.proposals).to be_empty
      end
    end

    context "without proposals" do
      let(:answers) { [{ answer: "Alles gut.", proposals: [] }] }

      it "does not ask again" do
        ask("What is missing?")

        expect(sent[:asks].size).to eq(1)
      end
    end
  end

  describe "the MCP tools" do
    it "offers the read-only MCP tools and explains them" do
      ask("How many?")

      expect(sent[:tools].map(&:name)).to include("search_work_packages", "list_statuses")
      expect(sent[:tools].map(&:name)).not_to include("update_work_package")
      expect(sent[:system]).to include(AI::Assistance::OutputRules::TOOLS, %("id":#{project.id}))
    end

    context "when the model calls a tool" do
      before do
        allow(llm).to receive(:ask) do
          thinking = RubyLLM::Thinking.new(text: "Let me count them.")
          sent[:on_end_message].call(instance_double(RubyLLM::Message, tool_call?: true, content: nil, thinking:))
          sent[:tools].find { it.name == "search_work_packages" }.call({ "project_id" => project.id })
          instance_double(RubyLLM::Message, content: { "answer" => "One.", "proposals" => [] })
        end
      end

      it "runs it as the user and records it with its result, and the model's text before it" do
        message = ask("How many?")

        expect(message.content).to eq("One.")
        tool_call = message.events.find { it["kind"] == "tool_call" }
        expect(tool_call["data"]).to include("name" => "search_work_packages", "arguments" => { "project_id" => project.id },
                                             "result" => include('"total"'))
        expect(message.events.find { it["kind"] == "thought" }["data"]).to eq("text" => "Let me count them.")
        expect(message.events.find { it["kind"] == "answer" }["data"]).to include("tool_calls" => 1)
      end
    end

    context "when the model calls tools without end" do
      before do
        allow(llm).to receive(:ask) do
          tool = sent[:tools].find { it.name == "search_work_packages" }
          (AI::Assistance::ToolCalls::HARD_LIMIT + 1).times { |page| tool.call({ "project_id" => page }) }
        end
      end

      it "fails the answer" do
        message = ask("How many?")

        expect(message).to be_failed
        expect(message.events.last["data"]).to include("error" => "AI::Assistance::ToolCalls::Exceeded")
      end
    end

    context "when the skill opts out of the tools" do
      let(:skill) { create(:ai_assistant_skill, prompt: "Check it.", use_tools: false) }

      it "offers no tools and does not mention them" do
        ask("How many?")

        expect(sent).not_to have_key(:tools)
        expect(sent[:system]).not_to include(AI::Assistance::OutputRules::TOOLS)
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

  context "when the answer timed out while the model was working" do
    let(:answer) do
      { answer: "Late answer",
        proposals: [{ severity: "none", area: "none", text: "Neuer Betreff", evidence: [],
                      changes: [{ field: "subject", value: "New subject" }] }] }
    end

    it "keeps the answer failed and stores nothing" do
      allow(llm).to receive(:ask) do
        AI::AssistantChatMessage.pending.update_all(status: "failed")
        instance_double(RubyLLM::Message, content: answer.deep_stringify_keys)
      end

      message = ask("Hello")

      expect(message).to be_failed
      expect(message.content).to eq("")
      expect(message.proposals).to be_empty
      expect(message.events.pluck("kind")).to include("late")
    end
  end

  context "without a work package" do
    let(:skill) { create(:ai_assistant_skill, :chat, prompt: "Help.", offered_on: "everywhere") }
    let(:chat) { create(:ai_assistant_chat, skill:, user:, work_package: nil, project:) }
    let(:answer) do
      { answer: "Drei offene Arbeitspakete.",
        proposals: [{ severity: "none", area: "none", text: "Neuer Betreff", evidence: [],
                      changes: [{ field: "subject", value: "New subject" }] }] }
    end

    it "sends the project as context, asks for no proposals and stores none" do
      message = ask("Was ist offen?")

      expect(message).to be_done
      expect(message.content).to eq("Drei offene Arbeitspakete.")
      expect(message.proposals).to be_empty
      expect(sent[:system]).to include(AI::Assistance::OutputRules::NO_PROPOSALS, %("identifier":"#{project.identifier}"))
      expect(sent[:system]).not_to include("change_options", "Secret note")
    end
  end
end
