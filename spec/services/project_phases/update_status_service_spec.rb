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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ProjectPhases::UpdateStatusService, type: :model do
  shared_let(:project) { create(:project) }

  let(:user) { create(:user) }
  let(:initial_statuses) { %w[open open open open] }
  let(:target_index) { 0 }
  let(:permissions) { [:edit_project_phases] }

  # Each factory call creates its own definition, so positions follow creation order.
  let!(:phases) do
    initial_statuses.map { |status| create(:project_phase, project:, status:) }
  end
  let(:target) { phases[target_index] }
  let(:service) { described_class.new(user:, model: target) }

  def statuses
    phases.map { it.reload.status }
  end

  before do
    mock_permissions_for(user) do |mock|
      permissions.each { |permission| mock.allow_in_project(permission, project:) }
    end

    # Project#available_phases is scoped through Project.allowed_to (a SQL scope that
    # mock_permissions_for does not cover), so without these stubs it is empty.
    allow(Project).to receive(:allowed_to).with(user, :view_project_attributes).and_return(Project.all)
    allow(Project).to receive(:allowed_to).with(user, :view_project_phases).and_return(Project.all)
  end

  describe "changing the status of a single phase" do
    let(:target_index) { 1 }

    it "persists the new status on the phase" do
      expect(service.call(status: "in_progress")).to be_success
      expect(target.reload.status).to eq "in_progress"
    end

    it "does not touch phases of other projects" do
      other = create(:project_phase, status: "open")

      expect { service.call(status: "completed") }.not_to change { other.reload.status }
    end
  end

  describe "cascading" do
    # [initial statuses, index of the phase being changed, new status, expected statuses]
    {
      "open" => [
        # Reopens everything after the phase, leaves earlier phases alone
        [%w[completed completed in_progress open], 1, "open", %w[completed open open open]],
        [%w[in_progress open open open],           0, "open", %w[open open open open]],
        [%w[completed completed completed completed], 1, "open", %w[completed open open open]],
        [%w[completed in_progress open open],      2, "open", %w[completed in_progress open open]],
        # Nothing has started yet: nothing to cascade
        [%w[open open open open],                  2, "open", %w[open open open open]]
      ],
      "in_progress" => [
        # Completes earlier phases, opens later ones
        [%w[open open open open],                  2, "in_progress", %w[completed completed in_progress open]],
        [%w[completed completed in_progress open], 1, "in_progress", %w[completed in_progress open open]],
        [%w[completed completed completed completed], 1, "in_progress", %w[completed in_progress open open]],
        [%w[open open open open], 0, "in_progress", %w[in_progress open open open]]
      ],
      "completed" => [
        # Completes earlier phases, never opens anything
        [%w[open open open open],                  2, "completed", %w[completed completed completed open]],
        [%w[open open in_progress open],           1, "completed", %w[completed completed in_progress open]],
        [%w[completed in_progress open open],      3, "completed", %w[completed completed completed completed]],
        [%w[open open open open],                  0, "completed", %w[completed open open open]]
      ]
    }.each do |status, cases|
      context "when setting a phase to #{status}" do
        cases.each do |initial, index, new_status, expected|
          context "with phases #{initial.join(', ')} and changing phase #{index + 1}" do
            let(:initial_statuses) { initial }
            let(:target_index) { index }

            it "results in #{expected.join(', ')}" do
              expect(service.call(status: new_status)).to be_success
              expect(statuses).to eq expected
            end
          end
        end
      end
    end

    context "with an inactive phase in between" do
      let!(:phases) do
        [
          create(:project_phase, project:, status: "open"),
          create(:project_phase, :inactive, project:, status: "open"),
          create(:project_phase, project:, status: "open"),
          create(:project_phase, project:, status: "open")
        ]
      end
      let(:target_index) { 2 }

      it "leaves the inactive phase untouched" do
        expect(service.call(status: "in_progress")).to be_success
        expect(statuses).to eq %w[completed open in_progress open]
      end
    end

    context "when a phase of another project exists" do
      let!(:other_phases) do
        create_list(:project_phase, 2, status: "open")
      end
      let(:target_index) { 3 }

      it "does not cascade into the other project" do
        expect { service.call(status: "completed") }
          .not_to change { other_phases.map { it.reload.status } }
      end
    end
  end

  describe "failures" do
    let(:initial_statuses) { %w[open open open open] }
    let(:target_index) { 2 }

    context "without permission to edit project phases" do
      let(:permissions) { [] }

      it "fails and changes nothing" do
        expect(service.call(status: "in_progress")).to be_failure
        expect(statuses).to eq initial_statuses
      end
    end

    context "with an unknown status" do
      it "fails and changes nothing" do
        expect(service.call(status: "bogus")).to be_failure
        expect(statuses).to eq initial_statuses
      end
    end
  end
end
