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

RSpec.describe Backlogs::Sprints::StartService do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:status1) { create(:status) }
  shared_let(:status2) { create(:status) }
  shared_let(:project) { create(:project, types: [type_task]) }
  let(:status) { "in_planning" }
  let(:sprint) { create(:sprint, project:, status:) }
  let(:user) { create(:admin) }
  let(:instance) { described_class.new(user:, model: sprint) }

  subject(:result) { instance.call(send_notifications: false) }

  before do
    create(:workflow, type: type_task, old_status: status1, new_status: status2, role: create(:project_role))
  end

  context "when no task board exists yet" do
    it "creates the board and starts the sprint", :aggregate_failures do
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to be_present
    end
  end

  context "when a task board already exists" do
    let!(:existing_board) { create(:board_grid_with_query, project:, linked: sprint) }

    it "starts the sprint without creating another board", :aggregate_failures do
      expect { result }.not_to change(Boards::Grid, :count)
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to eq(existing_board)
    end
  end

  context "when a task board exists for another project" do
    let!(:other_project) { create(:project) }
    let!(:other_board) { create(:board_grid_with_query, project: other_project, linked: sprint) }

    it "creates a board for the sprint project", :aggregate_failures do
      expect { result }.to change(Boards::Grid, :count).by(1)
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to be_present
      expect(sprint.task_board_for(project)).not_to eq(other_board)
      expect(sprint.task_board_for(other_project)).to eq(other_board)
    end
  end

  context "when board creation fails" do
    let(:service_result) { ServiceResult.failure(message: "something went wrong") }
    let(:service) { instance_double(Boards::SprintTaskBoardCreateService, call: service_result) }

    before do
      allow(Boards::SprintTaskBoardCreateService)
        .to receive(:new)
        .with(user: User.system)
        .and_return(service)
    end

    it "returns failure and leaves the sprint in planning", :aggregate_failures do
      expect(result).not_to be_success
      expect(sprint.reload).to be_in_planning
      expect(sprint.task_board_for(project)).to be_nil
    end
  end

  context "when the sprint has no start date" do
    let(:sprint) { create(:sprint, project:, start_date: nil) }

    it "fails contract validation without activating the sprint", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:base)).to include(:dates_required)
      expect(sprint.reload).to be_in_planning
    end
  end

  context "when the sprint has no finish date" do
    let(:sprint) { create(:sprint, project:, finish_date: nil) }

    it "fails contract validation without activating the sprint", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:base)).to include(:dates_required)
      expect(sprint.reload).to be_in_planning
    end
  end

  context "when another active sprint exists in the project" do
    let!(:active_sprint) { create(:sprint, project:, status: "active") }

    it "fails contract validation without creating a board", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:status)).to include(:only_one_active_sprint_allowed)
      expect(sprint.reload).to be_in_planning
      expect(sprint.task_board_for(project)).to be_nil
    end
  end

  context "when the database unique constraint rejects sprint activation" do
    before do
      allow(sprint)
        .to receive(:active!)
        .and_raise(ActiveRecord::RecordNotUnique)
    end

    it "returns failure with the active sprint error", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors[:status]).to include("only one active sprint is allowed per project.")
      expect(result.message).to be_present
      expect(sprint.reload).to be_in_planning
      expect(sprint.task_board_for(project)).to be_nil
    end
  end

  context "when the sprint is already active" do
    let(:status) { "active" }

    it "fails contract validation", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:status)).to include(:must_be_in_planning)
      expect(sprint.reload).to be_active
    end
  end

  context "when the sprint is already completed" do
    let(:status) { "completed" }

    it "fails contract validation", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:status)).to include(:must_be_in_planning)
      expect(sprint.reload).to be_completed
    end
  end

  context "when the user lacks permission" do
    let(:user) { create(:user) }

    it "fails contract validation", :aggregate_failures do
      expect(result).not_to be_success
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(sprint.reload).to be_in_planning
    end
  end

  context "when the sprint source shares with all projects" do
    let(:project) { create(:project, sprint_sharing: "share_all_projects", types: [type_task]) }
    let!(:receiving_project) { create(:project, sprint_sharing: "receive_shared", types: [type_task]) }

    it "creates boards for both owning and receiving projects", :aggregate_failures do
      expect { result }.to change(Boards::Grid, :count).by(2)
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to be_present
      expect(sprint.task_board_for(receiving_project)).to be_present
    end
  end

  context "when the user cannot manage boards in a receiving project" do
    let(:project) { create(:project, sprint_sharing: "share_all_projects", types: [type_task]) }
    let!(:receiving_project) { create(:project, sprint_sharing: "receive_shared", types: [type_task]) }
    let(:user) do
      create(:user, member_with_permissions: { project => [:start_complete_sprint] })
    end

    it "still succeeds because boards are created as the system user", :aggregate_failures do
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to be_present
      expect(sprint.task_board_for(receiving_project)).to be_present
    end
  end

  context "when work packages exist in an additional project" do
    let!(:receiving_project) { create(:project, types: [type_task]) }

    before do
      create(:work_package, project: receiving_project, type: type_task, sprint:)
    end

    it "creates boards for both owning and work package projects", :aggregate_failures do
      expect { result }.to change(Boards::Grid, :count).by(2)
      expect(result).to be_success
      expect(sprint.reload).to be_active
      expect(sprint.task_board_for(project)).to be_present
      expect(sprint.task_board_for(receiving_project)).to be_present
    end
  end
end
