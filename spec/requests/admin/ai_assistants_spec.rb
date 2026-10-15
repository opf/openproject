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

RSpec.describe "Admin AI assistants", :skip_csrf, type: :rails_request, with_flag: { ai_assistance: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:owner) { create(:user, firstname: "Ada", lastname: "Owner") }
  shared_let(:global_assistant) { create(:ai_assistant, name: "QA assistance") }
  shared_let(:personal_assistant) { create(:ai_assistant, name: "My helper", principal: owner) }

  current_user { admin }

  describe "GET /admin/ai_assistants" do
    it "lists one section per assistant, global first, with its owner linked and its skills" do
      skill = create(:ai_assistant_skill, assistant: global_assistant, label: "Check it", offered_on: "everywhere")
      group = create(:group, lastname: "Release team")
      create(:ai_assistant, name: "Team helper", principal: group)

      get admin_ai_assistants_path

      expect(response).to have_http_status(:ok)
      page = response.parsed_body
      expect(page.css("[data-test-selector='ai-assistant-section']").size).to eq(3)
      expect(response.body.index("QA assistance")).to be < response.body.index("Team helper")
      expect(response.body.index("Team helper")).to be < response.body.index("My helper")
      owners = page.css("[data-test-selector='ai-assistant-owner']")
      expect(owners.map { it.text.squish }).to eq(["Global", "Release team", "Ada Owner"])
      expect(owners[1].at_css("a")["href"]).to eq(edit_group_path(group))
      expect(owners[2].at_css("a")["href"]).to eq(edit_user_path(owner))
      expect(page.at_css("a[href='#{edit_admin_ai_assistant_skill_path(global_assistant, skill)}']").text).to include("Check it")
    end

    it "deletes a skill from the list and returns to the list" do
      skill = create(:ai_assistant_skill, assistant: global_assistant)

      delete admin_ai_assistant_skill_path(global_assistant, skill), params: { back: "list" }

      expect(response).to redirect_to(admin_ai_assistants_path)
      expect(AI::AssistantSkill.exists?(skill.id)).to be(false)
    end
  end

  describe "a personal assistant" do
    it "can be edited with a model, and keeps its owner" do
      get edit_admin_ai_assistant_path(personal_assistant)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("personal assistant of Ada Owner", "ai_assistant[model_id]")

      patch admin_ai_assistant_path(personal_assistant),
            params: { ai_assistant: { name: "Renamed", model_id: "test-model", active: "0" } }

      expect(personal_assistant.reload).to have_attributes(name: "Renamed", model_id: "test-model",
                                                           active: false, principal: owner)
    end
  end

  describe "skill conditions" do
    let(:skill) { create(:ai_assistant_skill, assistant: global_assistant, conditions: { status_ids: [1] }) }
    let(:type) { create(:type) }

    it "stores the chosen ids, and a cleared input clears its condition" do
      patch admin_ai_assistant_skill_path(global_assistant, skill),
            params: { ai_assistant_skill: { label: "Checked" },
                      condition_type_ids: ["", type.id.to_s], condition_status_ids: [""] }

      expect(skill.reload.conditions).to eq("type_ids" => [type.id])

      get edit_admin_ai_assistant_path(global_assistant)
      expect(page).to have_css("[data-test-selector='ai-skill-conditions']", text: "1 type")
    end
  end

  describe "the icon of a skill" do
    let(:skill) { create(:ai_assistant_skill, assistant: global_assistant) }

    it "stores the chosen icon, and an empty choice uses the default again" do
      patch admin_ai_assistant_skill_path(global_assistant, skill), params: { ai_assistant_skill: { icon: "bug" } }
      expect(skill.reload.icon).to eq("bug")

      patch admin_ai_assistant_skill_path(global_assistant, skill), params: { ai_assistant_skill: { icon: "default" } }
      expect(skill.reload.icon).to eq("light-bulb")
      expect(skill.chosen_icon).to be_nil
    end

    it "shows the icon menu left of the label" do
      skill.update!(icon: "bug")

      get edit_admin_ai_assistant_skill_path(global_assistant, skill)

      expect(response.body).to include('data-test-selector="ai-assistance-icon-picker"', "octicon-bug",
                                       'name="ai_assistant_skill[label]"')
    end
  end

  describe "the tools setting of a skill" do
    let(:skill) { create(:ai_assistant_skill, assistant: global_assistant) }

    it "stores the opt-out" do
      patch admin_ai_assistant_skill_path(global_assistant, skill), params: { ai_assistant_skill: { use_tools: "0" } }

      expect(skill.reload.use_tools).to be(false)
    end

    it "previews the system prompt for both states, and shows the saved one" do
      skill.update!(prompt: "Check it.", use_tools: false)

      get edit_admin_ai_assistant_skill_path(global_assistant, skill)

      expect(page).to have_css("[data-test-selector='ai-skill-prompt-preview'].d-none",
                               text: AI::Assistance::OutputRules::TOOLS, visible: :all)
      expect(page).to have_css("[data-test-selector='ai-skill-prompt-preview-without-tools']:not(.d-none)",
                               text: "Check it.", visible: :all)
    end
  end

  describe "POST /admin/ai_assistants" do
    it "creates a global assistant" do
      post admin_ai_assistants_path, params: { ai_assistant: { name: "Release helper" } }

      expect(AI::Assistant.find_by!(name: "Release helper").principal).to be_nil
    end

    it "creates an assistant for a group" do
      group = create(:group, lastname: "Release team")

      post admin_ai_assistants_path, params: { ai_assistant: { name: "Release helper", principal_id: group.id } }

      expect(AI::Assistant.find_by!(name: "Release helper").principal).to eq(group)
    end

    it "does not make a user the owner" do
      post admin_ai_assistants_path, params: { ai_assistant: { name: "Release helper", principal_id: owner.id } }

      expect(AI::Assistant.find_by!(name: "Release helper").principal).to be_nil
    end
  end

  describe "a group assistant" do
    it "keeps its group on update" do
      group = create(:group, lastname: "Release team")
      assistant = create(:ai_assistant, name: "Team helper", principal: group)

      patch admin_ai_assistant_path(assistant), params: { ai_assistant: { name: "Renamed", principal_id: "" } }
      expect(assistant.reload).to have_attributes(name: "Renamed", principal: group)
    end
  end
end
