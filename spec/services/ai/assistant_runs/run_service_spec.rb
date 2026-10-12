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

RSpec.describe AI::AssistantRuns::RunService do
  shared_let(:project) { create(:project) }
  shared_let(:open_status) { create(:status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:user) { create(:user, language: "de", member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:skill) { create(:ai_assistant_skill) }

  let(:work_package) { create(:work_package, project:, status: closed_status) }

  subject(:call) { described_class.new(skill:, work_package: work_package.reload, user:).call }

  before { create(:work_package, project:, parent: work_package, status: open_status) }

  it "stores a finished run with the rule findings" do
    run = call.result

    expect(call).to be_success
    expect(run).to be_finished
    expect(run).to have_attributes(user:, work_package:, work_package_lock_version: work_package.reload.lock_version)
    expect(run.findings.map(&:rule_key)).to include("closed_with_open_descendants")
    expect(run.findings).to all(have_attributes(source: "rule", change_set: nil))
  end

  it "records that the menu started the run" do
    expect(call.result).to be_triggered_by_menu
    expect(call.result.automation).to be_nil
  end

  it "writes the findings in the user's language" do
    expect(call.result.locale).to eq("de")
    expect(call.result.findings.first.text).to eq(
      I18n.t("ai_assistance.health_check.rules.closed_with_open_descendants", count: 1, locale: :de)
    )
  end

  it "does not start the AI judgement without an LLM connection" do
    expect(call.result.not_checked).to include("area" => "ai_judgement", "reason" => "no_llm_connection")
  end

  context "with an LLM connection", with_flag: { llm_connection: true }, with_settings: { llm_features_enabled: true } do
    let(:connection) { create(:llm_connection, active: true) }

    before do
      connection.update_column(:default_chat_model_id,
                               create(:llm_model, llm_connection: connection, external_id: "chat-model").id)
    end

    it "runs only the rules when the skill has no prompt" do
      without_prompt = create(:ai_assistant_skill, prompt: nil)
      run = described_class.new(skill: without_prompt, work_package: work_package.reload, user:).call.result

      expect(run.not_checked).to include("area" => "ai_judgement", "reason" => "no_prompt")
      expect(run).to be_finished
    end

    it "starts the AI judgement in a job" do
      expect { call }.to have_enqueued_job(AI::AssistantRuns::JudgementJob)
      expect(call.result).to be_ai_running
    end

    it "opens the running run instead of starting a second one" do
      first = described_class.new(skill:, work_package: work_package.reload, user:).call.result

      expect(call.result).to eq(first)
      expect(AI::AssistantRun.count).to eq(1)
    end

    it "starts again when the running one is older than the timeout" do
      first = described_class.new(skill:, work_package: work_package.reload, user:).call.result
      first.update_column(:created_at, 11.minutes.ago)

      expect(call.result).not_to eq(first)
      expect(first.reload).to be_finished
      expect(first.not_checked).to include("area" => "ai_judgement", "reason" => "timed_out")
    end
  end

  context "with a skill key that is not registered" do
    let(:skill) { create(:ai_assistant_skill, skill_key: "unknown") }

    it "fails and stores nothing" do
      expect(call).to be_failure
      expect(AI::AssistantRun.count).to eq(0)
    end
  end
end
