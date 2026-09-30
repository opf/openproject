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

RSpec.describe TimeEntry do
  describe "#journals (and the saving of them)" do
    shared_let(:project) { create(:project) }
    shared_let(:work_package) { create(:work_package, project:) }
    shared_let(:user) { create(:user) }
    shared_let(:other_user) { create(:user) }
    shared_let(:rate) { create(:hourly_rate, user:, project:, valid_from: Date.new(2026, 1, 8), rate: 1) }
    shared_let(:activity) { create(:time_entry_activity) }

    current_user { user }

    context "on creation" do
      let!(:journable) do
        described_class.new
      end

      include_examples "journaled values for",
                       new_values_set: {
                         "user_id" => :user,
                         "project_id" => :project,
                         "comments" => "Initial comment",
                         "hours" => 60,
                         "activity_id" => :activity,
                         "spent_on" => Date.new(2026, 1, 9),
                         "overridden_costs" => 30.0,
                         "costs" => 20.0,
                         "logged_by_id" => :other_user,
                         "start_time" => 22,
                         "time_zone" => "UTC",
                         "entity_id" => :work_package,
                         "entity_type" => "WorkPackage"
                       },
                       expected_values: {
                         "user_id" => [nil, :user],
                         "project_id" => [nil, :project],
                         "comments" => [nil, "Initial comment"],
                         "hours" => [nil, 60],
                         "activity_id" => [nil, :activity],
                         "spent_on" => [nil, Date.new(2026, 1, 9)],
                         # The next three are deduced from spent_on automatically
                         "tyear" => [nil, 2026],
                         "tmonth" => [nil, 1],
                         "tweek" => [nil, 2],
                         "overridden_costs" => [nil, 30.0],
                         # This one is calculated based on the rate and the amount
                         "costs" => [nil, 60.0],
                         "rate_id" => [nil, :rate],
                         "logged_by_id" => [nil, :other_user],
                         "start_time" => [nil, 22],
                         "time_zone" => [nil, "UTC"],
                         "entity_id" => [nil, :work_package],
                         "entity_type" => [nil, "WorkPackage"]
                       },
                       expect_new_journal: true,
                       expect_predecessor_changed: false do
        it "results in created_at and updated_at being the same on the time entry" do
          journable.save!
          # Just to ensure that there actually is nothing hidden in the DB
          journable.reload

          expect(work_package.created_at)
            .to eql work_package.updated_at
        end
      end
    end

    context "when nothing is changed" do
      context "for a time entry that has only been created (single journal)" do
        # Not using a factory here as that already produced a journal without a data journal
        let!(:journable) do
          described_class.create!(
            user:,
            project:,
            comments: "Initial comment",
            hours: 60,
            activity:,
            spent_on: Date.new(2026, 1, 9),
            overridden_costs: 30.0,
            costs: 20.0,
            logged_by: other_user,
            start_time: 22,
            time_zone: "UTC",
            entity: work_package
          )
        end

        include_examples "no journaled value changes for",
                         new_values_set: {}
      end
    end
  end
end
