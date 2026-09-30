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

Date::DATE_FORMATS[:wday_iso_date] = "%a %Y-%m-%d" # Fri 2022-08-05

RSpec.shared_examples "no email deliveries" do
  it "does not perform any email deliveries" do
    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries)
      .to be_empty
  end
end

RSpec.shared_examples "it creates records" do |model:, expected_count:|
  it "creates #{expected_count} records of #{model}" do
    expect(model.count).to eq(expected_count)
  end
end

RSpec.shared_examples "it is compatible with the automatic scheduling mode" do
  # rubocop:disable Layout/LineContinuationLeadingSpace
  it "has successors in automatic mode with dates matching closest predecessor's dates and relation lag", :aggregate_failures do
    days = WorkPackages::Shared::WorkingDays.new
    relations = Relation.follows.includes(:from, :to).to_a
                        .sort_by!(&:predecessor_date)
                        .reverse!
                        .uniq(&:successor_id)
    relations.each do |relation|
      predecessor = relation.to
      successor = relation.from
      pred_date = relation.predecessor_date
      succ_date = relation.successor_date
      next if pred_date.nil? && succ_date.nil?

      expect(successor).to be_schedule_automatically,
                           "Expected successor '#{successor.subject}' to be scheduled automatically"

      expected_lag = days.lag(pred_date, succ_date)
      relation_lag = relation.lag || 0
      message =
        "Relation from predecessor '#{predecessor.subject}' (date: #{pred_date.to_fs(:wday_iso_date)})\n" \
        "             to successor '#{successor.subject}' (date: #{succ_date.to_fs(:wday_iso_date)})\n" \
        "has invalid lag #{relation_lag} (expected #{expected_lag})\n" \
        "Try the following:\n" \
        "- Adjust successor dates to start #{(succ_date - days.soonest_working_day(pred_date + 1)).to_i} day(s) earlier\n" \
        "- Increase predecessor duration by #{expected_lag - relation_lag}\n"
      expect(expected_lag).to eq(relation_lag), message
    end
  end

  it "has parents in automatic mode with dates matching children's dates", :aggregate_failures do
    parents = WorkPackage.where(id: WorkPackage.select(:parent_id).distinct).includes(:children)
    parents.each do |parent|
      expected_start_date = parent.children.minimum(:start_date)
      if expected_start_date
        expect(parent.start_date)
          .to eq(expected_start_date),
              "Expected parent '#{parent.subject}' to have start date #{expected_start_date.to_fs(:wday_iso_date)}"
      end
      expected_due_date = parent.children.maximum(:due_date)
      if expected_due_date
        expect(parent.due_date)
          .to eq(expected_due_date),
              "Expected parent '#{parent.subject}' to have due date #{expected_due_date.to_fs(:wday_iso_date)}"
      end
      expect(parent).to be_schedule_automatically,
                        "Expected parent '#{parent.subject}' to be scheduled automatically"
    end
  end
  # rubocop:enable Layout/LineContinuationLeadingSpace
end
