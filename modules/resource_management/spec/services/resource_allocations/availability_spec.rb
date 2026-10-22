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

RSpec.describe ResourceAllocations::Availability do
  let(:user) { create(:user) }
  let(:monday) { Date.new(2026, 1, 5) }
  let(:tuesday) { Date.new(2026, 1, 6) }
  let(:friday) { Date.new(2026, 1, 9) }

  subject(:availability) { described_class.new(user:) }

  before do
    # Mon-Fri 8h => 2400 minutes of capacity across the work week.
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
  end

  describe "#overbooked? / #overbooked_dates / #overbooked_allocation_ids" do
    let(:wednesday) { Date.new(2026, 1, 7) }

    it "is not overbooked when the allocations fit" do
      create(:resource_allocation, principal: user, allocated_time: 600)
      create(:resource_allocation, principal: user, allocated_time: 600)

      expect(availability).not_to be_overbooked
      expect(availability.overbooked_dates).to be_empty
      expect(availability.overbooked_allocation_ids).to be_empty
    end

    it "marks the days with overtime and every allocation with time on them" do
      first = create(:resource_allocation, principal: user, allocated_time: 1500)
      second = create(:resource_allocation, principal: user, allocated_time: 1500)

      expect(availability).to be_overbooked
      expect(availability.overbooked_dates).to eq((monday..friday).to_a)
      expect(availability.overbooked_allocation_ids).to contain_exactly(first.id, second.id)
    end

    it "marks an allocation that fits on its own when it shares an overbooked day" do
      fitting = create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)
      exceeding = create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: wednesday)
      create(:resource_allocation, principal: user, allocated_time: 480, start_date: friday, end_date: friday)

      expect(availability.overbooked_dates).to contain_exactly(monday, tuesday, wednesday)
      expect(availability.overbooked_allocation_ids).to contain_exactly(fitting.id, exceeding.id)
      expect(availability.overbooked_dates_of(fitting)).to eq([monday, tuesday])
      expect(availability.overbooked_dates_of(exceeding)).to eq([monday, tuesday, wednesday])
    end

    it "does not mark a global non-working day" do
      create(:non_working_day, date: tuesday)
      create(:resource_allocation, principal: user, allocated_time: 960 + 120, start_date: monday, end_date: wednesday)

      expect(availability.overbooked_dates).to contain_exactly(monday, wednesday)
    end

    it "marks an allocation whose window has no working day" do
      unplannable = create(:resource_allocation, principal: user, allocated_time: 240,
                                                 start_date: friday + 1, end_date: friday + 2)

      expect(availability).to be_overbooked
      expect(availability.overbooked_dates).to be_empty
      expect(availability.overbooked_allocation_ids).to contain_exactly(unplannable.id)
    end

    it "counts allocations across all projects (capacity is user-level)" do
      in_project_a = create(:resource_allocation, principal: user, allocated_time: 1500,
                                                  entity: create(:work_package, project: create(:project)))
      in_project_b = create(:resource_allocation, principal: user, allocated_time: 1500,
                                                  entity: create(:work_package, project: create(:project)))

      expect(availability.overbooked_allocation_ids).to contain_exactly(in_project_a.id, in_project_b.id)
    end

    it "ignores filter-based allocations that have no principal" do
      create(:resource_allocation, principal: user, allocated_time: 600)
      create(:resource_allocation, :with_user_filter, start_date: monday, end_date: friday, allocated_time: 5000)

      expect(availability).not_to be_overbooked
    end
  end

  describe "#scheduled_minutes_within" do
    it "sums the minutes booked within the range" do
      create(:resource_allocation, principal: user, allocated_time: 600)
      create(:resource_allocation, principal: user, allocated_time: 600)

      expect(availability.scheduled_minutes_within(monday..friday)).to eq(1200)
    end

    it "is zero when nothing is booked in the range" do
      expect(availability.scheduled_minutes_within(monday..friday)).to eq(0)
    end
  end

  describe "#overbooking_with" do
    let(:wednesday) { Date.new(2026, 1, 7) }

    it "is not overbooked when the prospective allocation fits" do
      create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)

      prospective = build(:resource_allocation, principal: user, allocated_time: 480,
                                                start_date: wednesday, end_date: wednesday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).not_to be_overbooked
      expect(overbooking).to have_attributes(overtime_minutes: 0, period: nil, unplannable: false)
    end

    it "sums the overtime the prospective allocation generates over the period it falls into" do
      create(:resource_allocation, principal: user, allocated_time: 1920)

      overbooking = availability.overbooking_with(build(:resource_allocation, principal: user, allocated_time: 960))

      expect(overbooking).to be_overbooked
      expect(overbooking).to have_attributes(overtime_minutes: 480, period: monday..friday)
    end

    it "ignores an existing overbooking the prospective allocation does not add to" do
      create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)
      create(:resource_allocation, principal: user, allocated_time: 240, start_date: friday + 1, end_date: friday + 2)

      prospective = build(:resource_allocation, principal: user, allocated_time: 480,
                                                start_date: friday, end_date: friday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).not_to be_overbooked
    end

    it "counts only the overtime it adds on an already overbooked day" do
      create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)

      prospective = build(:resource_allocation, principal: user, allocated_time: 240,
                                                start_date: monday, end_date: monday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).to have_attributes(overtime_minutes: 240, period: monday..monday)
    end

    it "includes the overtime of existing work it pushes back, beyond its own period" do
      create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: wednesday)

      prospective = build(:resource_allocation, principal: user, allocated_time: 960,
                                                start_date: monday, end_date: tuesday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).to have_attributes(overtime_minutes: 480, period: monday..wednesday)
    end

    it "replaces the persisted version of an allocation being edited" do
      existing = create(:resource_allocation, principal: user, allocated_time: 2000)
      existing.allocated_time = 2400

      expect(availability.overbooking_with(existing)).not_to be_overbooked
    end

    it "reports the overtime of an already overbooked allocation that is edited without changing it" do
      existing = create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)

      expect(availability.overbooking_with(existing)).to have_attributes(overtime_minutes: 120, period: monday..monday)
    end

    it "is overbooked without any overtime when the window contains no working day" do
      prospective = build(:resource_allocation, principal: user, allocated_time: 240,
                                                start_date: friday + 1, end_date: friday + 2)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).to be_overbooked
      expect(overbooking).to have_attributes(overtime_minutes: 0, period: nil, unplannable: true)
    end

    context "with a schedule to resume" do
      let(:thursday) { Date.new(2026, 1, 8) }
      let(:next_monday) { Date.new(2026, 1, 12) }
      let(:next_wednesday) { Date.new(2026, 1, 14) }
      let(:next_friday) { Date.new(2026, 1, 16) }

      let!(:early) do
        create(:resource_allocation, principal: user, allocated_time: 1200, start_date: monday, end_date: wednesday)
      end
      let!(:long) do
        create(:resource_allocation, principal: user, allocated_time: 3000, start_date: monday, end_date: next_friday)
      end
      let!(:late) do
        create(:resource_allocation, principal: user, allocated_time: 1000, start_date: next_monday, end_date: next_wednesday)
      end

      # Runs over every allocation of the user from their first day on,
      # without the stored schedule.
      def full_overbooking_with(allocation, user: allocation.principal)
        others = ResourceAllocation.allocated.for_principal(user).where.not(id: allocation.id).to_a
        all = others + [allocation]
        range = all.map(&:start_date).min..all.map(&:end_date).max
        calendar = ResourceAllocations::WorkingTimeCalendar.new(user:, range:)
        baseline = overtime_by_date(ResourceAllocations::FitCalculator.new(calendar:, allocations: others).call)
        prospective = ResourceAllocations::FitCalculator.new(calendar:, allocations: all).call
        added = overtime_by_date(prospective)
                  .to_h { |date, minutes| [date, minutes - baseline[date]] }
                  .select { |_date, minutes| minutes.positive? }

        ResourceAllocations::ProspectiveOverbooking.new(
          overtime_minutes: added.values.sum,
          period: (added.keys.min..added.keys.max if added.any?),
          unplannable: prospective.unplannable.key?(allocation)
        )
      end

      def overtime_by_date(result)
        result.overtime.values.flat_map(&:to_a).each_with_object(Hash.new(0)) do |(date, minutes), sums|
          sums[date] += minutes
        end
      end

      it "matches a full computation for a new allocation" do
        prospective = build(:resource_allocation, principal: user, allocated_time: 2400,
                                                  start_date: thursday, end_date: next_monday + 1)

        expect(availability.overbooking_with(prospective)).to eq(full_overbooking_with(prospective))
      end

      it "matches a full computation including overtime spread back before the allocation starts" do
        prospective = build(:resource_allocation, principal: user, allocated_time: 960,
                                                  start_date: thursday, end_date: friday)
        overbooking = availability.overbooking_with(prospective)

        expect(overbooking).to eq(full_overbooking_with(prospective))
        expect(overbooking.period.begin).to be < thursday
      end

      it "matches a full computation for an edit moving the start earlier" do
        late.start_date = wednesday

        expect(availability.overbooking_with(late)).to eq(full_overbooking_with(late))
      end

      it "matches a full computation for an edit moving the start later" do
        early.assign_attributes(start_date: tuesday, end_date: thursday)

        expect(availability.overbooking_with(early)).to eq(full_overbooking_with(early))
      end

      it "matches a full computation for an edit changing the allocated time" do
        long.allocated_time = 4000

        expect(availability.overbooking_with(long)).to eq(full_overbooking_with(long))
      end

      it "matches a full computation for an edit changing the principal" do
        other = create(:user)
        create(:user_working_hours, user: other, valid_from: Date.new(2025, 1, 1))
        create(:resource_allocation, principal: other, allocated_time: 2000, start_date: monday, end_date: thursday)
        late.assign_attributes(principal: other, start_date: tuesday)

        expect(described_class.new(user: other).overbooking_with(late)).to eq(full_overbooking_with(late))
      end

      it "matches a full computation for staffing a filter-based allocation" do
        filter_based = create(:resource_allocation, :with_user_filter, allocated_time: 1500,
                                                                       start_date: wednesday, end_date: next_monday)
        filter_based.principal = user

        expect(availability.overbooking_with(filter_based)).to eq(full_overbooking_with(filter_based))
      end

      it "matches a full computation for an unplannable allocation" do
        prospective = build(:resource_allocation, principal: user, allocated_time: 240,
                                                  start_date: friday + 1, end_date: friday + 2)
        overbooking = availability.overbooking_with(prospective)

        expect(overbooking).to eq(full_overbooking_with(prospective))
        expect(overbooking).to have_attributes(unplannable: true)
      end
    end
  end

  describe "#utilization_ratio" do
    it "expresses booked time as a percentage of the window's capacity" do
      create(:resource_allocation, principal: user, allocated_time: 1200) # half of the 2400 min Mon-Fri capacity

      expect(availability.utilization_ratio(monday..friday)).to eq(50)
    end

    it "exceeds 100% when the user is overbooked" do
      create(:resource_allocation, principal: user, allocated_time: 3600)

      expect(availability.utilization_ratio(monday..friday)).to eq(150)
    end

    it "rounds to the nearest whole percent" do
      create(:resource_allocation, principal: user, allocated_time: 800) # 800 / 2400 => 33.33%

      expect(availability.utilization_ratio(monday..friday)).to eq(33)
    end

    it "sums every allocation overlapping the window" do
      create(:resource_allocation, principal: user, allocated_time: 600)
      create(:resource_allocation, principal: user, allocated_time: 1200)

      expect(availability.utilization_ratio(monday..friday)).to eq(75)
    end

    it "counts the time the schedule places within the window" do
      create(:resource_allocation, principal: user, allocated_time: 2000, start_date: monday, end_date: friday)

      expect(availability.utilization_ratio(monday..tuesday)).to eq(100)
      expect(availability.utilization_ratio(friday..friday)).to eq(17)
    end

    it "follows the schedule instead of spreading an allocation evenly over its window" do
      create(:resource_allocation, principal: user, allocated_time: 2400, start_date: monday, end_date: friday + 7)

      expect(availability.utilization_ratio(monday..friday)).to eq(100)
      expect(availability.utilization_ratio((monday + 7)..(friday + 7))).to eq(0)
    end

    it "counts the overtime placed within the window" do
      create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)

      expect(availability.utilization_ratio(monday..monday)).to eq(125)
    end

    it "measures each day against the user's working hours on that day" do
      part_timer = create(:user)
      create(:user_working_hours, user: part_timer, valid_from: Date.new(2025, 1, 1), monday: 240)
      part_availability = described_class.new(user: part_timer)
      next_monday = Date.new(2026, 1, 12)

      create(:resource_allocation, principal: part_timer, entity: create(:work_package),
                                   allocated_time: 720, start_date: friday, end_date: next_monday)

      expect(part_availability.utilization_ratio(friday..friday)).to eq(100)
      expect(part_availability.utilization_ratio(next_monday..next_monday)).to eq(100)
    end

    it "ignores allocations that fall entirely outside the window" do
      create(:resource_allocation, principal: user, allocated_time: 2400, start_date: monday, end_date: tuesday)

      expect(availability.utilization_ratio(friday..friday)).to eq(0)
    end

    it "is nil when the window has no working capacity" do
      weekend = Date.new(2026, 1, 10)..Date.new(2026, 1, 11)

      expect(availability.utilization_ratio(weekend)).to be_nil
    end
  end
end
