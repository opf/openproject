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

RSpec.describe Backlogs::Sprints::UpdateService, type: :model do
  let(:project) { create(:project, sprint_sharing: Projects::SprintSharing::RECEIVE_SHARED) }
  let(:source_project) { create(:project, sprint_sharing: Projects::SprintSharing::SHARE_ALL_PROJECTS) }
  let(:sprint) { create(:sprint, project: source_project, name: "Sprint 1") }
  let(:user) do
    create(:user, member_with_permissions: { project => project_permissions, source_project => source_project_permissions })
  end
  let(:project_permissions) { %i[view_sprints create_sprints] }
  let(:source_project_permissions) { %i[view_sprints] }
  let(:attributes) { { goals_attributes: [{ project_id: project.id, text: "Ship dashboard" }] } }

  subject(:service_call) do
    described_class.new(user:, model: sprint).call(attributes:)
  end

  it "persists the goal for the supplied goal project" do
    expect { service_call }.to change(SprintGoal, :count).by(1)

    expect(service_call.result.goal_text_for(project)).to eq("Ship dashboard")
  end

  context "when a goal already exists" do
    let!(:goal) do
      create(:sprint_goal, sprint:, project:, text: "Old goal")
    end
    let(:attributes) { { goals_attributes: [{ id: goal.id, project_id: project.id, text: "Ship dashboard" }] } }

    it "updates the existing goal" do
      expect { service_call }.not_to change(SprintGoal, :count)

      expect(sprint.reload.goal_text_for(project)).to eq("Ship dashboard")
    end

    context "with a blank goal" do
      let(:attributes) { { goals_attributes: [{ id: goal.id, text: "", _destroy: "1" }] } }

      it "removes the existing goal" do
        expect { service_call }.to change(SprintGoal, :count).by(-1)

        expect(sprint.goal_text_for(project)).to be_nil
      end
    end
  end

  context "without create_sprints permission in the goal project" do
    let(:project_permissions) { %i[view_sprints] }

    it "does not persist the goal" do
      expect { service_call }.not_to change(SprintGoal, :count)

      expect(service_call).not_to be_success
    end
  end

  context "when the sprint is not visible to the goal project" do
    let(:unrelated_project) { create(:project) }
    let(:user) do
      create(
        :user,
        member_with_permissions: {
          unrelated_project => %i[view_sprints create_sprints],
          source_project => source_project_permissions
        }
      )
    end
    let(:attributes) { { goals_attributes: [{ project_id: unrelated_project.id, text: "Ship dashboard" }] } }

    it "does not persist the goal" do
      expect { service_call }.not_to change(SprintGoal, :count)

      expect(service_call).not_to be_success
    end
  end

  context "when a duplicate goal would be created" do
    before do
      create(:sprint_goal, sprint:, project:, text: "Old goal")
    end

    it "returns a failed service result" do
      expect { service_call }.not_to change(SprintGoal, :count)

      expect(service_call).not_to be_success
      expect(service_call.errors).not_to be_empty
    end
  end

  context "with sprint attributes" do
    let(:attributes) { { name: "Renamed" } }
    let(:project_permissions) { %i[view_sprints] }
    let(:source_project_permissions) { %i[view_sprints create_sprints] }

    it "updates the sprint through the regular update contract" do
      expect(service_call).to be_success

      expect(sprint.reload.name).to eq("Renamed")
    end
  end

  context "with sprint attributes and no source project edit permission" do
    let(:attributes) { { name: "Renamed" } }
    let(:project_permissions) { %i[view_sprints create_sprints] }
    let(:source_project_permissions) { %i[view_sprints] }

    it "does not update the sprint" do
      expect(service_call).not_to be_success

      expect(sprint.reload.name).to eq("Sprint 1")
    end
  end

  context "with sprint attributes and goal attributes" do
    let(:attributes) do
      {
        name: "Renamed",
        goals_attributes: [{ project_id: project.id, text: "Ship dashboard" }]
      }
    end
    let(:project_permissions) { %i[view_sprints create_sprints] }
    let(:source_project_permissions) { %i[view_sprints create_sprints] }

    it "updates both in one request" do
      expect(service_call).to be_success

      expect(sprint.reload.name).to eq("Renamed")
      expect(sprint.goal_text_for(project)).to eq("Ship dashboard")
    end
  end
end
