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
    end
  end
end
