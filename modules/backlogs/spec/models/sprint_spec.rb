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

RSpec.describe Sprint do
  let(:project) { create(:project) }
  let(:sprint_status) { "in_planning" }

  subject(:sprint) do
    described_class.new(name: "Sprint 1",
                        project:,
                        start_date: Time.zone.today,
                        finish_date: Time.zone.today + 14.days,
                        status: sprint_status)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys) }

    it "allows nil start and finish dates" do
      sprint.start_date = nil
      sprint.finish_date = nil
      expect(sprint).to be_valid
    end

    it "allows a nil finish date when start date is present" do
      sprint.start_date = Time.zone.today
      sprint.finish_date = nil
      expect(sprint).to be_valid
    end

    context "with active sprint validation" do
      let(:sprint_status) { "active" }

      it { is_expected.to validate_presence_of(:start_date) }
      it { is_expected.to validate_presence_of(:finish_date) }

      it "validates finish_date is after or equal to start_date" do
        sprint.finish_date = sprint.start_date - 1.day
        expect(sprint).not_to be_valid
        expect(sprint.errors[:finish_date]).to include(/must be greater than or equal to/)
      end

      it "does not validate finish_date comparison when start_date is nil" do
        sprint.start_date = nil
        sprint.finish_date = Time.zone.today
        expect(sprint).not_to be_valid
        expect(sprint.errors[:start_date]).to be_present
        expect(sprint.errors[:finish_date]).not_to include(/must be greater than or equal to/)
      end

      it "still validates finish_date presence even when start_date is nil" do
        sprint.start_date = nil
        sprint.finish_date = nil
        expect(sprint).not_to be_valid
        expect(sprint.errors[:finish_date]).to be_present
      end

      it "allows one active sprint per project" do
        expect(sprint).to be_valid
      end

      it "prevents multiple active sprints in the same project" do
        create(:sprint, project:, status: "active")
        expect(sprint).not_to be_valid
        expect(sprint.errors[:status]).to include("only one active sprint is allowed per project.")
      end

      it "allows multiple active sprints in different projects" do
        other_project = create(:project)
        create(:sprint, project: other_project, status: "active")
        expect(sprint).to be_valid
      end

      it "allows updating an existing active sprint" do
        sprint.save!
        sprint.name = "Updated Sprint"
        expect(sprint).to be_valid
      end

      it "allows multiple non-active sprints in the same project" do
        create(:sprint, project:, status: "completed")
        create(:sprint, project:, status: "in_planning")
        sprint.status = "in_planning"
        expect(sprint).to be_valid
      end
    end
  end

  describe "enums" do
    it "has status enum with correct values" do
      expect(described_class.statuses.keys).to contain_exactly("in_planning", "active", "completed")
    end

    it "status defaults to in_planning" do
      expect(sprint).to be_in_planning
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:work_packages).inverse_of(:sprint).dependent(:nullify) }
    it { is_expected.to have_many(:task_boards).dependent(:nullify) }
    it { is_expected.to have_many(:goals).class_name("SprintGoal").inverse_of(:sprint).dependent(:delete_all) }
    it { is_expected.to belong_to(:project) }
  end

  describe "nested goal attributes" do
    let(:sprint) { create(:sprint, project:) }

    it { is_expected.to accept_nested_attributes_for(:goals).allow_destroy(true).limit(1) }

    it "assigns goal attributes" do
      sprint.assign_attributes(
        goals_attributes: [{ project_id: project.id, text: "Ship MVP" }]
      )

      expect(sprint.goals.first).to have_attributes(project_id: project.id, text: "Ship MVP")
    end

    it "rejects blank new goals" do
      expect do
        sprint.assign_attributes(
          goals_attributes: [{ project_id: project.id, text: "" }]
        )
      end.not_to change { sprint.goals.length }
    end

    it "marks existing blanked goals for destruction" do
      goal = create(:sprint_goal, sprint:, project:, text: "Old goal")

      sprint.assign_attributes(
        goals_attributes: [{ id: goal.id, text: "", _destroy: "1" }]
      )

      expect(sprint.goals.find { |sprint_goal| sprint_goal.id == goal.id }).to be_marked_for_destruction
    end

    it "limits nested assignment to one contextual goal" do
      expect do
        sprint.assign_attributes(
          goals_attributes: [
            { project_id: project.id, text: "First goal" },
            { project_id: project.id, text: "Second goal" }
          ]
        )
      end.to raise_error(ActiveRecord::NestedAttributes::TooManyRecords)
    end
  end

  describe "#task_board_for" do
    let(:sprint) { create(:sprint, project:) }
    let(:other_project) { create(:project) }

    context "when a sprint task board exists" do
      let!(:board) do
        create(:board_grid_with_query,
               project:,
               name: "Renamed board",
               linked: sprint)
      end

      it "returns the existing board for the requested project" do
        expect(sprint.task_board_for(project)).to eq(board)
      end

      it "supports multiple task boards across projects" do
        other_board = create(:board_grid_with_query, project: other_project, linked: sprint)

        expect(sprint.task_board_for(project)).to eq(board)
        expect(sprint.task_board_for(other_project)).to eq(other_board)
      end
    end

    context "when only same-name or same-filter boards exist" do
      let!(:same_name_board) { create(:board_grid_with_query, project:, name: "#{project.name}: #{sprint.name}") }
      let!(:matching_filters_board) do
        create(:board_grid_with_query,
               project:,
               options: {
                 "filters" => [{ "sprint_id" => { "operator" => "=", "values" => [sprint.id.to_s] } }]
               })
      end

      it "returns nil" do
        expect(sprint.task_board_for(project)).to be_nil
      end
    end

    context "when only another project's board exists" do
      let!(:other_board) { create(:board_grid_with_query, project: other_project, linked: sprint) }

      it "returns nil for the requested project" do
        expect(sprint.task_board_for(project)).to be_nil
      end
    end
  end

  describe "work_package association" do
    let(:sprint) { create(:sprint, project:) }
    let(:work_package) { create(:work_package, project:, sprint:) }

    it "can have work packages associated" do
      expect(sprint.work_packages).to include(work_package)
    end

    it "nullifies work_package sprint_id when destroyed" do
      work_package_id = work_package.id
      sprint.destroy!
      expect(WorkPackage.find(work_package_id).sprint_id).to be_nil
    end
  end

  describe "#work_packages_for" do
    let(:sprint) { create(:sprint, project:) }
    let(:other_project) { create(:project) }
    let!(:wp1) { create(:work_package, project:, sprint:) }
    let!(:wp2) { create(:work_package, project:, sprint:) }
    let!(:wp3_no_position) do
      create(:work_package, project:, sprint:).tap { |wp| wp.update_columns(position: nil) }
    end
    let!(:wp_other) { create(:work_package, project: other_project, sprint:) }

    context "when the association is not preloaded" do
      it "returns only work packages belonging to the given project with one query" do
        expect { sprint.work_packages_for(project) }.to have_a_query_limit(1)
        expect(sprint.work_packages_for(project)).to contain_exactly(wp1, wp2, wp3_no_position)
      end

      it "excludes work packages from other projects" do
        expect(sprint.work_packages_for(project)).not_to include(wp_other)
      end

      it "orders positioned work packages by position, with nil positions last" do
        expect(sprint.work_packages_for(project).to_a).to eq([wp1, wp2, wp3_no_position])
      end
    end

    context "when the association is preloaded" do
      before { sprint.work_packages.load }

      it "returns only work packages belonging to the given project without querying" do
        expect { sprint.work_packages_for(project) }.to have_a_query_limit(0)
        expect(sprint.work_packages_for(project)).to contain_exactly(wp1, wp2, wp3_no_position)
      end

      it "excludes work packages from other projects" do
        expect(sprint.work_packages_for(project)).not_to include(wp_other)
      end

      it "orders positioned work packages by position, with nil positions last" do
        expect(sprint.work_packages_for(project)).to eq([wp1, wp2, wp3_no_position])
      end
    end
  end

  describe "#owned_by?" do
    let(:sprint) { create(:sprint, project:) }
    let(:other_project) { create(:project) }

    it "returns true when the sprint belongs to the given project" do
      expect(sprint.owned_by?(project)).to be true
    end

    it "returns false when the sprint belongs to a different project" do
      expect(sprint.owned_by?(other_project)).to be false
    end
  end

  describe "#shared_with?" do
    let(:sprint) { create(:sprint, project:) }
    let(:receiver_project) { create(:project, sprint_sharing: "receive_shared") }
    let(:other_project) { create(:project, sprint_sharing: "no_sharing") }

    context "when the sprint is owned by the project" do
      it "returns false" do
        expect(sprint.shared_with?(project)).to be false
      end
    end

    context "when the sprint is visible to the project but not owned" do
      before do
        project.update(sprint_sharing: "share_all_projects")
      end

      it "returns true" do
        expect(sprint.shared_with?(receiver_project)).to be true
      end
    end

    context "when the sprint is not visible to the project" do
      it "returns false" do
        expect(sprint.shared_with?(other_project)).to be false
      end
    end

    context "with subproject sharing" do
      let(:parent_project) { create(:project, sprint_sharing: "share_subprojects") }
      let(:child_project) { create(:project, parent: parent_project, sprint_sharing: "receive_shared") }
      let(:parent_sprint) { create(:sprint, project: parent_project) }

      it "returns true when sprint is shared from parent to child" do
        expect(parent_sprint.shared_with?(child_project)).to be true
      end

      it "returns false for the owning parent project" do
        expect(parent_sprint.shared_with?(parent_project)).to be false
      end
    end

    context "with work package assignment to unrelated project" do
      let(:unrelated_sprint) { create(:sprint, project: other_project) }

      before do
        create(:work_package, project:, sprint: unrelated_sprint)
      end

      it "returns true when sprint is visible via work package assignment" do
        expect(unrelated_sprint.shared_with?(project)).to be true
      end
    end
  end

  describe "#visible_to?" do
    let(:sprint) { create(:sprint, project:) }
    let(:receiver_project) { create(:project, sprint_sharing: "receive_shared") }
    let(:other_project) { create(:project, sprint_sharing: "no_sharing") }

    context "when the sprint is owned by the project" do
      it "returns true" do
        expect(sprint.visible_to?(project)).to be true
      end
    end

    context "when the sprint is shared with the project" do
      before do
        project.update(sprint_sharing: "share_all_projects")
      end

      it "returns true" do
        expect(sprint.visible_to?(receiver_project)).to be true
      end
    end

    context "when the sprint is not visible to the project" do
      it "returns false" do
        expect(sprint.visible_to?(other_project)).to be false
      end
    end

    context "with global sharing" do
      let(:global_sharer) { create(:project, sprint_sharing: "share_all_projects") }
      let(:global_sprint) { create(:sprint, project: global_sharer) }

      it "returns true for projects that receive shared sprints" do
        expect(global_sprint.visible_to?(receiver_project)).to be true
      end

      it "returns true for the owning project" do
        expect(global_sprint.visible_to?(global_sharer)).to be true
      end

      it "returns false for projects with no_sharing mode" do
        expect(global_sprint.visible_to?(other_project)).to be false
      end
    end

    context "with subproject sharing" do
      let(:parent_project) { create(:project, sprint_sharing: "share_subprojects") }
      let(:child_project) { create(:project, parent: parent_project, sprint_sharing: "receive_shared") }
      let(:grandchild_project) { create(:project, parent: child_project, sprint_sharing: "receive_shared") }
      let(:parent_sprint) { create(:sprint, project: parent_project) }

      it "returns true for direct child receiving shared sprints" do
        expect(parent_sprint.visible_to?(child_project)).to be true
      end

      it "returns true for grandchild receiving shared sprints" do
        expect(parent_sprint.visible_to?(grandchild_project)).to be true
      end

      it "returns true for the owning parent project" do
        expect(parent_sprint.visible_to?(parent_project)).to be true
      end
    end

    context "with work package assignment" do
      let(:unrelated_project) { create(:project, sprint_sharing: "no_sharing") }
      let(:unrelated_sprint) { create(:sprint, project: unrelated_project) }

      before do
        create(:work_package, project:, sprint: unrelated_sprint)
      end

      it "returns true when sprint is visible via work package assignment" do
        expect(unrelated_sprint.visible_to?(project)).to be true
      end

      it "returns true for the owning project" do
        expect(unrelated_sprint.visible_to?(unrelated_project)).to be true
      end
    end
  end

  describe "#goal_for" do
    let(:sprint) { create(:sprint, project:) }
    let!(:sprint_goal) { create(:sprint_goal, sprint:, project:, text: "Ship dashboard") }

    it "returns the goal for the given project" do
      expect(sprint.goal_for(project)).to eq(sprint_goal)
    end

    it "returns nil when no goal exists for the project" do
      other_project = create(:project)
      expect(sprint.goal_for(other_project)).to be_nil
    end

    it "returns an in-memory goal for an unsaved sprint" do
      sprint = build(:sprint, project:)
      sprint_goal = sprint.goals.build(project:, text: "Ship dashboard")

      expect(sprint.goal_for(project)).to eq(sprint_goal)
    end
  end

  describe "#goal_text_for" do
    let(:sprint) { create(:sprint, project:) }

    it "returns the goal text for the given project" do
      create(:sprint_goal, sprint:, project:, text: "Ship dashboard")

      expect(sprint.goal_text_for(project)).to eq("Ship dashboard")
    end

    it "returns nil when no goal exists for the project" do
      other_project = create(:project)

      expect(sprint.goal_text_for(other_project)).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the name" do
      expect(sprint.to_s).to eq("Sprint 1")
    end
  end
end
