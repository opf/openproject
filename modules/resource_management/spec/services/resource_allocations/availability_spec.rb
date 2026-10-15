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

  describe "#optimal_schedule" do
    it "distributes a feasible allocation across the days, summing back to its time" do
      create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)

      schedule = availability.optimal_schedule
      scheduled_minutes = schedule.by_date.values.flatten.sum(&:minutes)

      expect(scheduled_minutes).to eq(960)
      expect(schedule.capacity_on(monday)).to eq(480)
    end

    it "dates each entry with the day it is placed on" do
      create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)

      schedule = availability.optimal_schedule

      expect(schedule.entries_on(monday).map(&:allocated_on)).to eq([monday])
      expect(schedule.entries_on(tuesday).map(&:allocated_on)).to eq([tuesday])
    end

    context "when an allocation exceeds its window's capacity" do
      let(:wednesday) { Date.new(2026, 1, 7) }

      it "has no overtime when the allocation fits" do
        create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)

        expect(availability.optimal_schedule.entries_on(monday).sole.overtime_minutes).to eq(0)
      end

      it "merges the overtime into the allocation's single entry per day" do
        create(:resource_allocation, principal: user, allocated_time: 960 + 120, start_date: monday, end_date: tuesday)

        schedule = availability.optimal_schedule

        expect(schedule.entries_on(monday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
        expect(schedule.entries_on(tuesday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
      end

      it "schedules the full allocated time" do
        create(:resource_allocation, principal: user, allocated_time: 2400 + 300)

        expect(availability.optimal_schedule.by_date.values.flatten.sum(&:minutes)).to eq(2700)
      end

      it "adds an entry on days where the allocation has only overtime" do
        fitting = create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: tuesday)
        exceeding = create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: wednesday)

        schedule = availability.optimal_schedule

        expect(schedule.entries_on(monday).map { |entry| [entry.allocation, entry.minutes, entry.overtime_minutes] })
          .to contain_exactly([fitting, 480, 0], [exceeding, 160, 160])
        expect(schedule.entries_on(wednesday).sole)
          .to have_attributes(allocation: exceeding, minutes: 640, overtime_minutes: 160)
      end

      it "puts no time on a global non-working day" do
        create(:non_working_day, date: tuesday)
        create(:resource_allocation, principal: user, allocated_time: 960 + 120, start_date: monday, end_date: wednesday)

        schedule = availability.optimal_schedule

        expect(schedule.entries_on(tuesday)).to be_empty
        expect(schedule.entries_on(monday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
        expect(schedule.entries_on(wednesday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
      end

      it "puts no time on the user's non-working time" do
        create(:user_non_working_time, user:, start_date: tuesday, end_date: tuesday)
        create(:resource_allocation, principal: user, allocated_time: 960 + 120, start_date: monday, end_date: wednesday)

        schedule = availability.optimal_schedule

        expect(schedule.entries_on(tuesday)).to be_empty
        expect(schedule.entries_on(monday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
      end

      it "puts no time on weekends" do
        create(:resource_allocation, principal: user, allocated_time: 960 + 120, start_date: friday, end_date: friday + 3)

        schedule = availability.optimal_schedule

        expect(schedule.entries_on(friday + 1)).to be_empty
        expect(schedule.entries_on(friday + 2)).to be_empty
        expect(schedule.entries_on(friday).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
        expect(schedule.entries_on(friday + 3).sole).to have_attributes(minutes: 540, overtime_minutes: 60)
      end
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
      expect(overbooking).to have_attributes(days: [], unplannable: false)
    end

    it "lists the days on which the prospective allocation generates overtime" do
      create(:resource_allocation, principal: user, allocated_time: 1920)

      overbooking = availability.overbooking_with(build(:resource_allocation, principal: user, allocated_time: 960))

      expect(overbooking).to be_overbooked
      expect(overbooking.days.map(&:date)).to eq((monday..friday).to_a)
      expect(overbooking.days.first).to have_attributes(
        date: monday, working_minutes: 480, planned_minutes: 480, added_minutes: 96, overtime_minutes: 96
      )
      expect(overbooking.days.last).to have_attributes(
        date: friday, working_minutes: 480, planned_minutes: 0, added_minutes: 576, overtime_minutes: 96
      )
    end

    it "ignores an existing overbooking the prospective allocation does not add to" do
      create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)
      create(:resource_allocation, principal: user, allocated_time: 240, start_date: friday + 1, end_date: friday + 2)

      prospective = build(:resource_allocation, principal: user, allocated_time: 480,
                                                start_date: friday, end_date: friday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).not_to be_overbooked
    end

    it "includes an already overbooked day when it adds to the overtime there" do
      create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)

      prospective = build(:resource_allocation, principal: user, allocated_time: 240,
                                                start_date: monday, end_date: monday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking.days.sole).to have_attributes(
        date: monday, working_minutes: 480, planned_minutes: 600, added_minutes: 240, overtime_minutes: 360
      )
    end

    it "includes days on which it pushes existing work into overtime" do
      create(:resource_allocation, principal: user, allocated_time: 960, start_date: monday, end_date: wednesday)

      prospective = build(:resource_allocation, principal: user, allocated_time: 960,
                                                start_date: monday, end_date: tuesday)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking.days.map(&:date)).to eq([monday, tuesday, wednesday])
      expect(overbooking.days.last).to have_attributes(
        date: wednesday, working_minutes: 480, planned_minutes: 640, added_minutes: 0, overtime_minutes: 160
      )
    end

    it "replaces the persisted version of an allocation being edited" do
      existing = create(:resource_allocation, principal: user, allocated_time: 2000)
      existing.allocated_time = 2400

      expect(availability.overbooking_with(existing)).not_to be_overbooked
    end

    it "lists the overtime of an already overbooked allocation that is edited without changing it" do
      existing = create(:resource_allocation, principal: user, allocated_time: 600, start_date: monday, end_date: monday)

      expect(availability.overbooking_with(existing).days.sole).to have_attributes(
        date: monday, working_minutes: 480, planned_minutes: 0, added_minutes: 600, overtime_minutes: 120
      )
    end

    it "is overbooked without any days when the window contains no working day" do
      prospective = build(:resource_allocation, principal: user, allocated_time: 240,
                                                start_date: friday + 1, end_date: friday + 2)
      overbooking = availability.overbooking_with(prospective)

      expect(overbooking).to be_overbooked
      expect(overbooking).to have_attributes(days: [], unplannable: true)
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
