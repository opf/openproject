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

RSpec.describe AI::AssistantSkill do
  describe "conditions" do
    shared_let(:project) { create(:project) }
    shared_let(:other_project) { create(:project) }
    shared_let(:feature) { create(:type) }
    shared_let(:bug) { create(:type) }
    shared_let(:in_progress) { create(:status) }
    shared_let(:role) { create(:project_role) }

    let(:user) { create(:user, member_with_roles: { project => role }) }
    let(:work_package) { create(:work_package, project:, type: feature, status: in_progress) }
    let(:skill) { build(:ai_assistant_skill, conditions:) }
    let(:conditions) { {} }

    it "matches every work package without conditions" do
      expect(skill.conditions_fulfilled?(work_package, user)).to be(true)
    end

    it "keeps only the known keys and integer ids" do
      skill.conditions = { "type_ids" => ["", feature.id.to_s, feature.id.to_s], "status_ids" => [""], "other" => [1] }

      expect(skill.conditions).to eq("type_ids" => [feature.id])
    end

    it "drops the ids of deleted records when it is saved" do
      gone = create(:type)
      skill = create(:ai_assistant_skill, conditions: { type_ids: [feature.id, gone.id], status_ids: [in_progress.id] })
      gone.destroy
      skill.update!(conditions: { type_ids: [feature.id, gone.id], status_ids: [0] })

      expect(skill.reload.conditions).to eq("type_ids" => [feature.id])
    end

    context "with a type condition" do
      let(:conditions) { { type_ids: [bug.id] } }

      it "matches only work packages of those types" do
        expect(skill.conditions_fulfilled?(work_package, user)).to be(false)
        expect(skill.conditions_fulfilled?(create(:work_package, project:, type: bug), user)).to be(true)
      end
    end

    context "with a status and a project condition" do
      let(:conditions) { { status_ids: [in_progress.id], project_ids: [other_project.id] } }

      it "needs every condition to match" do
        expect(skill.conditions_fulfilled?(work_package, user)).to be(false)

        skill.conditions = { status_ids: [in_progress.id], project_ids: [project.id] }
        expect(skill.conditions_fulfilled?(work_package, user)).to be(true)
      end
    end

    context "with a role condition" do
      let(:conditions) { { role_ids: [role.id] } }

      it "matches users with that role in the work package's project" do
        expect(skill.conditions_fulfilled?(work_package, user)).to be(true)
        expect(skill.conditions_fulfilled?(work_package, create(:user))).to be(false)
      end

      it "matches admins, who can see and change every skill" do
        expect(skill.conditions_fulfilled?(work_package, create(:admin))).to be(true)
      end
    end
  end

  describe "#system_prompt" do
    let(:assistant) { build(:ai_assistant, instructions: "You help the COMMS team.") }
    let(:skill) { build(:ai_assistant_skill, :preset, assistant:, prompt: "Write a test plan.") }

    it "joins the assistant's instructions, the prompt and the generated output rules" do
      expect(skill.system_prompt(locale: "en")).to eq(
        "You help the COMMS team.\n\nWrite a test plan.\n\n#{AI::Assistance::OutputRules.new(skill, locale: 'en')}"
      )
    end

    it "is nil without a prompt, while the full prompt still shows the rest" do
      skill.prompt = ""

      expect(skill.system_prompt(locale: "en")).to be_nil
      expect(skill.full_system_prompt(locale: "en")).to start_with("You help the COMMS team.\n\nWrite \"answer\"")
    end

    it "explains the tools by default, and not when the skill opts out" do
      expect(skill.use_tools).to be(true)
      expect(skill.system_prompt(locale: "en")).to include(AI::Assistance::OutputRules::TOOLS)

      skill.use_tools = false
      expect(skill.system_prompt(locale: "en")).not_to include(AI::Assistance::OutputRules::TOOLS)
    end
  end

  describe "#icon" do
    let(:skill) { build(:ai_assistant_skill) }

    it "uses the icon of the variant by default, and the chosen one when set" do
      expect(skill.icon).to eq("light-bulb")
      expect(build(:ai_assistant_skill, :chat).icon).to eq("comment-discussion")

      skill.icon = "bug"
      expect(skill.icon).to eq("bug")
    end

    it "accepts only the listed icons" do
      skill.icon = "not-an-icon"

      expect(skill).not_to be_valid
      expect(skill.errors).to include(:icon)
    end
  end

  describe "#offered_at?" do
    let(:project) { create(:project) }
    let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
    let(:work_package) { create(:work_package, project:) }
    let(:skill) { create(:ai_assistant_skill) }
    let(:everywhere) { create(:ai_assistant_skill, :chat, offered_on: "everywhere") }

    def place(**) = AI::Assistance::Place.new(**)

    it "offers every skill on a work package, and only Everywhere skills elsewhere" do
      expect(skill.offered_at?(place(work_package:), user)).to be(true)
      expect(skill.offered_at?(place(project:), user)).to be(false)
      expect(everywhere.offered_at?(place(work_package:), user)).to be(true)
      expect(everywhere.offered_at?(place(project:), user)).to be(true)
      expect(everywhere.offered_at?(place, user)).to be(true)
    end

    it "offers a skill limited to projects only in those projects" do
      everywhere.update!(conditions: { project_ids: [project.id] })

      expect(everywhere.offered_at?(place(project:), user)).to be(true)
      expect(everywhere.offered_at?(place(project: create(:project)), user)).to be(false)
      expect(everywhere.offered_at?(place, user)).to be(false)
    end

    it "offers a skill limited to roles only in a project where the user has one" do
      role = user.roles_for_project(project).first
      everywhere.update!(conditions: { role_ids: [role.id] })

      expect(everywhere.offered_at?(place(project:), user)).to be(true)
      expect(everywhere.offered_at?(place, user)).to be(false)
    end

    it "drops type and status conditions from an Everywhere skill" do
      everywhere.update!(conditions: { type_ids: [create(:type).id], status_ids: [create(:status).id],
                                       project_ids: [project.id] })

      expect(everywhere.reload.conditions.keys).to eq(%w[project_ids])
    end
  end
end
