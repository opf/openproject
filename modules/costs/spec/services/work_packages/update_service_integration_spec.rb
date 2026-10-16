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

RSpec.describe WorkPackages::UpdateService, "integration", type: :model do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:target_project) { create(:project, types: [type]) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages move_work_packages]) }
  shared_let(:user) do
    create(:user, member_with_roles: { project => role, target_project => role })
  end

  let(:work_package) { create(:work_package, project:, type:) }

  subject do
    described_class
      .new(user:, model: work_package)
      .call(project_id: target_project.id, send_notifications: false)
  end

  context "when updating the project" do
    describe "time_entries" do
      let!(:time_entries) do
        create_list(:time_entry, 2, project:, entity: work_package)
      end

      it "moves the time entries along" do
        expect(subject)
          .to be_success

        expect(TimeEntry.where(id: time_entries.map(&:id)).pluck(:project_id).uniq)
          .to contain_exactly(target_project.id)
      end
    end

    describe "time entry costs" do
      shared_let(:logging_user) { create(:user) }

      let!(:source_rate) do
        create(:hourly_rate, user: logging_user, project:, rate: 10.0, valid_from: 2.years.ago)
      end
      let!(:target_rate) do
        create(:hourly_rate, user: logging_user, project: target_project, rate: 99.0, valid_from: 2.years.ago)
      end
      let!(:time_entry) do
        create(:time_entry,
               project:,
               entity: work_package,
               user: logging_user,
               logged_by: logging_user,
               hours: 2.0)
      end

      it "recalculates the costs using the target project's rate", :aggregate_failures do
        expect(time_entry.reload.costs).to eq(20.0)

        expect(subject)
          .to be_success

        time_entry.reload

        expect(time_entry.project_id).to eq(target_project.id)
        expect(time_entry.rate).to eq(target_rate)
        expect(time_entry.costs).to eq(198.0)
      end

      it "journals the move on the time entry",
         :aggregate_failures,
         with_settings: { journal_aggregation_time_minutes: 0 } do
        expect { subject }
          .to change { time_entry.journals.reload.count }
          .by(1)

        journal = time_entry.journals.last.data

        expect(journal.project_id).to eq(target_project.id)
        expect(journal.rate_id).to eq(target_rate.id)
        expect(journal.costs).to eq(198.0)
      end

      context "when the target project's rate changed after the time was logged" do
        let!(:historic_source_rate) do
          create(:hourly_rate, user: logging_user, project:, rate: 5.0, valid_from: 4.years.ago)
        end
        let!(:historic_target_rate) do
          create(:hourly_rate, user: logging_user, project: target_project, rate: 50.0, valid_from: 4.years.ago)
        end
        let!(:time_entry) do
          create(:time_entry,
                 project:,
                 entity: work_package,
                 user: logging_user,
                 logged_by: logging_user,
                 hours: 2.0,
                 spent_on: 3.years.ago.to_date)
        end

        it "re-rates using the rate valid on spent_on, not the current one", :aggregate_failures do
          expect(time_entry.reload.costs).to eq(10.0)

          expect(subject)
            .to be_success

          time_entry.reload

          expect(time_entry.rate).to eq(historic_target_rate)
          expect(time_entry.costs).to eq(100.0)
        end
      end
    end
  end
end
