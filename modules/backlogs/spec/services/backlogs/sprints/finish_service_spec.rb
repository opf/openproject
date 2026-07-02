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

require "rails_helper"

RSpec.describe Backlogs::Sprints::FinishService do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:open_status) { create(:status, is_closed: false) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:project) do
    create(:project,
           enabled_module_names: %w[backlogs work_package_tracking],
           backlog_considered_closed_statuses: [closed_status])
  end

  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages view_sprints manage_sprint_items start_complete_sprint]
           })
  end
  let(:sprint) { create(:sprint, project:, status: sprint_status) }
  let(:sprint_status) { "active" }
  let(:instance) { described_class.new(user:, model: sprint) }
  let(:call_params) { {} }

  subject(:result) { instance.call(**call_params) }

  context "when the sprint has no unfinished work packages" do
    it "completes the sprint", :aggregate_failures do
      expect(result).to be_success
      expect(sprint.reload).to be_completed
    end
  end

  context "when the sprint has a closed work package" do
    let!(:closed_wp) do
      create(:work_package, project:, sprint:, status: closed_status)
    end

    it "completes the sprint ignoring the closed work package", :aggregate_failures do
      expect(result).to be_success
      expect(sprint.reload).to be_completed
      expect(closed_wp.reload).to have_attributes(sprint:)
    end
  end

  context "when the sprint has a work package with an open-system-status configured as 'done' for the project" do
    let!(:done_like_status) { create(:status, is_closed: false) }
    let!(:done_like_wp) do
      # Add the non-closed status to the project's done_statuses so it is
      # treated as "finished" by the work packages scope.
      project.done_statuses << done_like_status
      create(:work_package, project:, sprint:, status: done_like_status)
    end

    it "completes the sprint treating the work package as finished and leaving it in the sprint",
       :aggregate_failures do
      expect(result).to be_success
      expect(sprint.reload).to be_completed
      # The WP is not moved — it stays in the completed sprint.
      expect(done_like_wp.reload).to have_attributes(sprint:)
    end
  end

  context "when the sprint has unfinished (open) work packages" do
    let!(:open_wp) do
      create(:work_package, project:, sprint:, status: open_status)
    end

    context "without specifying a target sprint" do
      it "returns failure with unfinished_work_packages error and leaves the sprint active", :aggregate_failures do
        expect(result).not_to be_success
        expect(result.includes_error?(:base, :unfinished_work_packages)).to be true
        expect(sprint.reload).to be_active
        expect(open_wp.reload).to have_attributes(sprint:)
      end
    end

    context "when specifying a target sprint to move the work packages to" do
      let(:target_sprint) { create(:sprint, project:, status: "in_planning") }

      let(:call_params) { { unfinished_action: "move_to_sprint", move_to_sprint_id: target_sprint.id } }

      it "moves the open work packages and completes the sprint", :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed
        expect(open_wp.reload).to have_attributes(sprint: target_sprint)
      end
    end

    context "when specifying a target sprint not shared with the project" do
      let(:other_project) { create(:project, enabled_module_names: %w[backlogs work_package_tracking]) }
      let(:target_sprint) { create(:sprint, project: other_project, status: "in_planning") }

      let(:call_params) { { unfinished_action: "move_to_sprint", move_to_sprint_id: target_sprint.id } }

      it "returns failure on the work package update and leaves the sprint active", :aggregate_failures do
        expect(result).not_to be_success
        expect(sprint.reload).to be_active
        expect(open_wp.reload).to have_attributes(sprint:)
      end
    end

    context "when moving to the top of the backlog" do
      let!(:existing_backlog_wp) do
        create(:work_package, project:, sprint: nil, status: open_status)
      end

      let(:call_params) { { unfinished_action: "move_to_top_of_backlog" } }

      it "unassigns from sprint, completes the sprint, and places WP before existing backlog items", :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed
        expect(open_wp.reload).to have_attributes(sprint: nil, position: be < existing_backlog_wp.reload.position)
      end
    end

    context "when moving to the bottom of the backlog" do
      let!(:existing_backlog_wp) do
        create(:work_package, project:, sprint: nil, status: open_status)
      end

      let(:call_params) { { unfinished_action: "move_to_bottom_of_backlog" } }

      it "unassigns from sprint, completes the sprint, and places WP after existing backlog items", :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed
        expect(open_wp.reload).to have_attributes(sprint: nil, position: be > existing_backlog_wp.reload.position)
      end
    end
  end

  context "when the sprint has multiple unfinished work packages also in other projects and a target sprint is given" do
    let(:target_sprint) { create(:sprint, project:, status: "in_planning") }
    # Permissions are not necessary for this. The change is carried out regardless.
    let(:other_project) { create(:project) }
    let!(:open_wp1) do
      create(:work_package, project:, sprint:, status: open_status)
    end
    let!(:open_wp2) do
      create(:work_package, project:, sprint:, status: open_status)
    end
    let!(:open_wp3_target_sprint) do
      create(:work_package, project:, sprint: target_sprint, status: open_status)
    end
    let!(:open_wp4_target_sprint) do
      create(:work_package, project:, sprint: target_sprint, status: open_status)
    end
    let!(:open_wp5_backlog) do
      create(:work_package, project:, sprint: nil, status: open_status)
    end
    let!(:open_wp1_other_project) do
      create(:work_package, project: other_project, sprint:, status: open_status)
    end
    let!(:open_wp2_other_project) do
      create(:work_package, project: other_project, sprint:, status: open_status)
    end
    let!(:open_wp3_other_project_backlog) do
      create(:work_package, project: other_project, sprint: nil, status: open_status)
    end
    let!(:closed_wp) do
      create(:work_package, project:, sprint:, status: closed_status)
    end

    context "when specifying a target sprint" do
      let(:call_params) { { unfinished_action: "move_to_sprint", move_to_sprint_id: target_sprint.id } }

      it "moves only open work packages to their correct position across project borders and completes the sprint",
         :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed

        # In the project's sprint (the one the work packages were moved to)
        expect(open_wp1.reload).to have_attributes(sprint: target_sprint, position: 1, project:)
        expect(open_wp2.reload).to have_attributes(sprint: target_sprint, position: 2, project:)
        expect(open_wp3_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 3, project:)
        expect(open_wp4_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 4, project:)

        # In the project's backlog
        expect(open_wp5_backlog.reload).to have_attributes(sprint: nil, position: 1, project:)

        # In the project's sprint
        expect(closed_wp.reload).to have_attributes(sprint:, position: 1, project:)

        # In the other project's target_sprint (newly added)
        expect(open_wp1_other_project.reload).to have_attributes(sprint: target_sprint, position: 1, project: other_project)
        expect(open_wp2_other_project.reload).to have_attributes(sprint: target_sprint, position: 2, project: other_project)
        expect(open_wp3_other_project_backlog.reload).to have_attributes(sprint: nil, position: 1, project: other_project)
      end
    end

    context "when specifying to move to the backlog's top" do
      let(:call_params) { { unfinished_action: "move_to_top_of_backlog" } }

      it "moves only open work packages to their correct position across project borders and completes the sprint",
         :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed

        # In the project's backlog
        expect(open_wp1.reload).to have_attributes(sprint: nil, position: 1, project:)
        expect(open_wp2.reload).to have_attributes(sprint: nil, position: 2, project:)
        expect(open_wp5_backlog.reload).to have_attributes(sprint: nil, position: 3, project:)

        # In the project's other sprint
        expect(open_wp3_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 1, project:)
        expect(open_wp4_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 2, project:)

        # In the project's sprint
        expect(closed_wp.reload).to have_attributes(sprint:, position: 1, project:)

        # In the other project's backlog
        expect(open_wp1_other_project.reload).to have_attributes(sprint: nil, position: 1, project: other_project)
        expect(open_wp2_other_project.reload).to have_attributes(sprint: nil, position: 2, project: other_project)
        expect(open_wp3_other_project_backlog.reload).to have_attributes(sprint: nil, position: 3, project: other_project)
      end
    end

    context "when specifying to move to the backlog's bottom" do
      let(:call_params) { { unfinished_action: "move_to_bottom_of_backlog" } }

      it "moves only open work packages to their correct position across project borders and completes the sprint",
         :aggregate_failures do
        expect(result).to be_success
        expect(sprint.reload).to be_completed

        # In the project's backlog
        expect(open_wp5_backlog.reload).to have_attributes(sprint: nil, position: 1, project:)
        expect(open_wp1.reload).to have_attributes(sprint: nil, position: 2, project:)
        expect(open_wp2.reload).to have_attributes(sprint: nil, position: 3, project:)

        # In the project's other sprint
        expect(open_wp3_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 1, project:)
        expect(open_wp4_target_sprint.reload).to have_attributes(sprint: target_sprint, position: 2, project:)

        # In the project's sprint
        # Position should be 1 but it is 2
        expect(closed_wp.reload).to have_attributes(sprint:, position: 2, project:)

        # In the other project's backlog
        expect(open_wp3_other_project_backlog.reload).to have_attributes(sprint: nil, position: 1, project: other_project)
        expect(open_wp1_other_project.reload).to have_attributes(sprint: nil, position: 2, project: other_project)
        expect(open_wp2_other_project.reload).to have_attributes(sprint: nil, position: 3, project: other_project)
      end
    end
  end

  context "when the sprint is not active" do
    let(:sprint_status) { "in_planning" }

    it "returns failure and leaves the sprint unchanged", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors[:status]).to be_present
      expect(sprint.reload).to be_in_planning
    end
  end

  context "when the sprint is already completed" do
    let(:sprint_status) { "completed" }

    it "returns failure and leaves the sprint unchanged", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors[:status]).to be_present
      expect(sprint.reload).to be_completed
    end
  end

  context "when the user lacks start_complete_sprint permission" do
    let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_work_packages view_sprints]
             })
    end

    it "returns an unauthorized error and leaves the sprint active", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.includes_error?(:base, :error_unauthorized)).to be true
      expect(sprint.reload).to be_active
    end
  end
end
