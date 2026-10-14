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

RSpec.describe AI::AssistantRuns::Review do
  shared_let(:project) { create(:project, enabled_internal_comments: true) }
  shared_let(:user) do
    create(:user, language: "de", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:connection) { create(:llm_connection, active: true) }
  shared_let(:model) { create(:llm_model, llm_connection: connection, external_id: "chat-model") }

  let(:work_package) { create(:work_package, project:, subject: "Old subject", description: "Old text") }
  let(:run) do
    create(:ai_assistant_run, user:, work_package:, status: "ai_running", locale: "de",
                              skill: create(:ai_assistant_skill, prompt: admin_prompt || "Check it."))
  end
  let(:admin_prompt) { nil }
  let(:answer) { { findings: [] } }
  let(:chat) { instance_double(RubyLLM::Chat) }
  let(:session) { instance_double(Llm::Session, chat:) }
  let(:sent) { {} }

  before do
    connection.update_column(:default_chat_model_id, model.id)
    allow(Llm::Session).to receive(:for).and_return(session)
    allow(chat).to receive(:with_instructions) { |text|
      sent[:system] = text
      chat
    }
    allow(chat).to receive(:with_temperature) { |value|
      sent[:temperature] = value
      chat
    }
    allow(chat).to receive(:with_schema) { |schema|
      sent[:schema] = schema
      chat
    }
    allow(chat).to receive(:ask) do |text|
      sent[:user] = text
      instance_double(RubyLLM::Message, content: answer.deep_stringify_keys)
    end
    create(:work_package_journal, journable: work_package, user:, notes: "Public note", version: 2)
    create(:work_package_journal, journable: work_package, user:, notes: "Secret note", version: 3, internal: true)
  end

  subject(:call) { User.execute_as(user) { described_class.new(run).call } }

  context "with findings in the answer" do
    let(:answer) do
      { findings: [
        { severity: "medium", area: "content", text: "Der Kommentar ändert den Umfang.",
          evidence: ["Public note"], changes: [{ field: "description", value: "New text" }] },
        { severity: "low", area: "content", text: "Ohne Beleg.", evidence: [], changes: [] },
        { severity: "low", area: "status", text: "Falsches Feld.", evidence: ["x"],
          changes: [{ field: "status", value: "No such status" }] }
      ] }
    end

    it "stores the findings with evidence, and only changes to allowed values" do
      call

      findings = run.reload.findings.ai
      expect(findings.size).to eq(2)
      expect(findings.first).to have_attributes(change_set: AI::Proposal.change_set_for({ "description" => "New text" }),
                                                base_lock_version: work_package.reload.lock_version)
      expect(findings.second.change_set).to be_nil
      expect(run).to be_finished
    end
  end

  it "sends the visible comments only, and asks for the user's language" do
    call

    expect(sent[:user]).to include("Public note")
    expect(sent[:user]).not_to include("Secret note")
    expect(JSON.parse(sent[:user])["work_package"]).to include("assignee", "responsible")
    expect(sent[:system]).to include(%(locale code "de"))
  end

  it "asks with a low temperature, so that the findings stay stable" do
    call

    expect(sent[:temperature]).to eq(described_class::TEMPERATURE)
  end

  context "with a prompt set by an admin" do
    let(:admin_prompt) { "Only check the subject." }

    it "sends the prompt and the generated output rules with the locale filled in" do
      call

      expect(sent[:system]).to start_with("Only check the subject.")
      expect(sent[:system]).to include(%(locale code "de".))
    end
  end

  context "when the model fails" do
    before { allow(chat).to receive(:ask).and_raise(Llm::Errors::TimeoutError, "slow") }

    it "keeps the run and lists the AI review as not checked" do
      call

      expect(run.reload).to be_finished
      expect(run.not_checked).to include("area" => "ai_review", "reason" => "failed")
    end
  end

  context "when the answer is not structured" do
    before do
      allow(chat).to receive(:ask).and_return(instance_double(RubyLLM::Message, content: "plain text"))
    end

    it "lists the AI review as not checked" do
      call

      expect(run.reload.not_checked).to include("area" => "ai_review", "reason" => "failed")
    end
  end
end
